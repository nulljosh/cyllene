import Charts
import SwiftUI

// Sales at a glance (10.12): the last 30 days of first downloads as a sparkline, from Apple's daily sales summary.

extension ASCClient {
    /// One day of the account's sales summary, cached on disk so every app reads the same file. "" when Apple has none.
    /// `final` days (older than three) are cached even when empty; newer ones may still be on the way, so they are asked again.
    func salesDay(vendor: String, _ day: String, final: Bool) async throws -> String {
        let dir = URL.cachesDirectory.appendingPathComponent("sales"), file = dir.appendingPathComponent("\(day).tsv")
        if let s = try? String(contentsOf: file, encoding: .utf8) { return s }
        var c = URLComponents(url: Self.base.appendingPathComponent("/v1/salesReports"), resolvingAgainstBaseURL: false)!
        c.queryItems = ["filter[frequency]": "DAILY", "filter[reportDate]": day, "filter[reportSubType]": "SUMMARY",
                        "filter[reportType]": "SALES", "filter[vendorNumber]": vendor].sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: c.url!)
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("application/a-gzip", forHTTPHeaderField: "Accept")
        let tsv: String
        do { tsv = Sales.text(try await send(req)) } catch let e as ASCError where e.status == 404 { tsv = "" }  // no sales that day, or not out yet
        if !tsv.isEmpty || final {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? tsv.write(to: file, atomically: true, encoding: .utf8)
        }
        return tsv
    }
}

struct SalesGlance: View {
    let client: ASCClient
    let app: String
    @AppStorage("vendorNumber") private var vendor = ""
    @State private var days: [Day] = []
    @State private var total = Sales.Totals()
    @State private var note: String?
    struct Day: Identifiable { let id: Int; let downloads: Int }

    /// Apple dates its reports in Pacific time; yesterday is the newest there can be.
    static func day(ago n: Int) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let c = cal.dateComponents([.year, .month, .day], from: cal.date(byAdding: .day, value: -n, to: .now)!)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    var proceeds: String? {
        guard total.proceeds != 0 else { return nil }
        if total.currencies.count == 1, let code = total.currencies.first { return total.proceeds.formatted(.currency(code: code)) + " proceeds" }
        return "proceeds in \(total.currencies.count) currencies"
    }

    var body: some View {
        Group {
            if vendor.isEmpty {
                Text("Add your vendor number in Settings to see sales here.").font(Theme.font(13)).foregroundStyle(Theme.muted)
            } else if let note, days.isEmpty {
                Text(note).font(Theme.font(13)).foregroundStyle(Theme.muted)
            } else if days.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last 30 days").font(Theme.font(13)).foregroundStyle(Theme.muted)
                        Text("\(total.downloads) \(total.downloads == 1 ? "download" : "downloads")").font(Theme.font(20, .semibold))
                        Text([total.redownloads > 0 ? "\(total.redownloads) redownloads" : nil, proceeds].compactMap { $0 }.joined(separator: " · "))
                            .font(Theme.font(13)).foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 0)
                    Chart(days) {
                        AreaMark(x: .value("Day", $0.id), y: .value("Downloads", $0.downloads)).foregroundStyle(Theme.accent.opacity(0.15)).interpolationMethod(.monotone)
                        LineMark(x: .value("Day", $0.id), y: .value("Downloads", $0.downloads)).foregroundStyle(Theme.accent).interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                    .chartXAxis(.hidden).chartYAxis(.hidden)
                    .frame(width: 120, height: 44)
                    .accessibilityLabel("Downloads each day for the last 30 days")
                }
            }
        }
        .task(id: vendor) {
            // QA: HERMES_VENDOR=<number> fills the vendor number on launch.
            if vendor.isEmpty, let v = ProcessInfo.processInfo.environment["HERMES_VENDOR"] { vendor = v; return }
            guard !vendor.isEmpty else { return }
            await load()
        }
    }

    private func load() async {
        let vendor = vendor.trimmingCharacters(in: .whitespaces), client = client
        var reports: [Int: String] = [:], failure: Error?
        await withTaskGroup(of: (Int, Result<String, Error>).self) { g in
            for n in 1...30 {
                g.addTask { (n, await Result { try await client.salesDay(vendor: vendor, Self.day(ago: n), final: n > 3) }) }
            }
            for await (n, r) in g {
                switch r { case .success(let s): reports[n] = s; case .failure(let e): failure = failure ?? e }
            }
        }
        if reports.isEmpty, let failure {
            let s = (failure as? ASCError)?.status
            note = s == 403 || s == 401 ? "Sales need a key with the Finance or Sales role. Change it in App Store Connect under Users and Access, Integrations." : failure.localizedDescription
            return
        }
        let rows = reports.mapValues { Sales.parse($0) }
        total = Sales.totals(rows.values.flatMap { $0 }, app: app)
        days = (1...30).reversed().map { Day(id: 30 - $0, downloads: Sales.totals(rows[$0] ?? [], app: app).downloads) }
    }
}
