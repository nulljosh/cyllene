import SwiftUI

/// What a version still needs before it can go to App Review, read straight from Apple, the way Helm's launch checklist does.
struct LaunchChecklist {
    var build = false
    var whatsNew = (filled: 0, of: 0)
    var description = (filled: 0, of: 0)
    var screenshots = false
    var contact = false

    /// States where a version can still change and be sent.
    static let editable: Set<String> = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"]
}

extension ASCClient {
    func checklist(version id: String) async throws -> LaunchChecklist {
        struct One<A: Decodable>: Decodable { struct Item: Decodable { let id: String; let attributes: A? }; let data: Item? }
        struct Empty: Decodable {}
        struct Loc: Decodable { let locale: String?; let whatsNew: String?; let description: String? }
        struct Review: Decodable { let contactEmail: String? }
        struct Sets: Decodable { let data: [Empty] }

        async let build = try? decode(One<Empty>.self, "/v1/appStoreVersions/\(id)/build", ["fields[builds]": "version"])
        async let review = try? decode(One<Review>.self, "/v1/appStoreVersions/\(id)/appStoreReviewDetail", ["fields[appStoreReviewDetails]": "contactEmail"])
        let locs = try await decode(Doc<Loc>.self, "/v1/appStoreVersions/\(id)/appStoreVersionLocalizations",
                                    ["fields[appStoreVersionLocalizations]": "locale,whatsNew,description", "limit": "50"]).data
        var c = LaunchChecklist()
        func filled(_ s: String?) -> Bool { !(s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        c.whatsNew = (locs.filter { filled($0.attributes.whatsNew) }.count, locs.count)
        c.description = (locs.filter { filled($0.attributes.description) }.count, locs.count)
        if let first = locs.first {
            let sets = try? await decode(Sets.self, "/v1/appStoreVersionLocalizations/\(first.id)/appScreenshotSets", ["limit": "10"])
            c.screenshots = !(sets?.data.isEmpty ?? true)
        }
        c.build = await build?.data != nil
        c.contact = filled(await review?.data?.attributes?.contactEmail)
        return c
    }
}

struct ChecklistView: View {
    let client: ASCClient
    let version: Doc<VersionAttrs>.Item
    @State private var list: LaunchChecklist?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Launch checklist · \(version.attributes.versionString ?? "") on \(Theme.platform(version.attributes.platform ?? ""))")
                .font(Theme.font(15, .semibold))
            if let c = list {
                item("Build attached", c.build)
                item("Description" + langs(c.description), c.description.of > 0 && c.description.filled == c.description.of)
                item("What's New" + langs(c.whatsNew), c.whatsNew.of > 0 && c.whatsNew.filled == c.whatsNew.of,
                     note: c.whatsNew.filled == 0 ? "Not needed on a first version" : nil)
                item("Screenshots", c.screenshots)
                item("Review contact", c.contact)
            } else if failed {
                Text("Could not read the checklist.").font(Theme.font(13)).foregroundStyle(Theme.muted)
            } else {
                ProgressView().frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .task {
            do { list = try await client.checklist(version: version.id) } catch { failed = true }
        }
    }

    /// "", or ", 2 of 3 languages" when a listing has more than one.
    private func langs(_ c: (filled: Int, of: Int)) -> String { c.of > 1 ? ", \(c.filled) of \(c.of) languages" : "" }

    private func item(_ title: String, _ done: Bool, note: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Theme.live : Theme.muted)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.font(14))
                if let note, !done { Text(note).font(Theme.font(12)).foregroundStyle(Theme.muted) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(done ? "done" : "to do")
    }
}
