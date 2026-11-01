import Foundation

// Apple's sales summary, read the same way on the Mac (monthly, through asc) and the phone (daily, straight from the API).
enum Sales {
    struct Row: Equatable { let appleId: String; let type: String; let units: Int; let proceeds: Double; var currency = "" }
    struct Totals: Equatable { var downloads = 0, redownloads = 0; var proceeds = 0.0; var currencies: Set<String> = [] }

    /// Apple's tab-separated summary. Product types starting 1 are first downloads, 3 redownloads; 7 (updates) is skipped.
    static func parse(_ tsv: String) -> [Row] {
        let lines = tsv.split(whereSeparator: \.isNewline).map { $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
        guard let head = lines.first, let id = head.firstIndex(of: "Apple Identifier"), let t = head.firstIndex(of: "Product Type Identifier"),
              let u = head.firstIndex(of: "Units"), let p = head.firstIndex(of: "Developer Proceeds") else { return [] }
        let cur = head.firstIndex(of: "Currency of Proceeds")
        return lines.dropFirst().compactMap { c in
            guard c.count > max(id, t, u, p) else { return nil }
            return Row(appleId: c[id], type: c[t], units: Int(Double(c[u]) ?? 0), proceeds: (Double(c[p]) ?? 0) * (Double(c[u]) ?? 0),
                       currency: cur.flatMap { $0 < c.count ? c[$0] : nil } ?? "")
        }
    }

    static func totals(_ rows: [Row], app: String) -> Totals {
        rows.filter { $0.appleId == app }.reduce(into: Totals()) { t, r in
            if r.type.hasPrefix("1") || r.type == "F1" { t.downloads += r.units }
            if r.type.hasPrefix("3") || r.type == "F3" { t.redownloads += r.units }
            t.proceeds += r.proceeds
            if r.proceeds != 0, !r.currency.isEmpty { t.currencies.insert(r.currency) }
        }
    }

    /// The report body as text. Apple sends a gzip file; anything else is taken as plain text.
    static func text(_ d: Data) -> String {
        let b = [UInt8](d)
        guard b.count > 18, b[0] == 0x1f, b[1] == 0x8b else { return String(decoding: b, as: UTF8.self) }
        var i = 10
        let flags = b[3]
        if flags & 4 != 0 { i += 2 + (Int(b[10]) | (Int(b[11]) << 8)) }   // extra field
        for bit: UInt8 in [8, 16] where flags & bit != 0 {                // file name, comment: zero-terminated
            while i < b.count, b[i] != 0 { i += 1 }
            i += 1
        }
        if flags & 2 != 0 { i += 2 }                                        // header checksum
        guard i < b.count - 8, let out = try? (Data(b[i..<(b.count - 8)]) as NSData).decompressed(using: .zlib) else { return "" }
        return String(decoding: out as Data, as: UTF8.self)
    }
}
