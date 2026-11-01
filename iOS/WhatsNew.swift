import SwiftUI

struct LocaleText: Decodable { let locale: String?; let whatsNew: String? }

extension ASCClient {
    func whatsNew(version id: String) async throws -> [Doc<LocaleText>.Item] {
        try await decode(Doc<LocaleText>.self, "/v1/appStoreVersions/\(id)/appStoreVersionLocalizations",
                         ["fields[appStoreVersionLocalizations]": "locale,whatsNew", "limit": "50"]).data
    }

    static func whatsNewBody(localization id: String, text: String) -> [String: Any] {
        ["data": ["type": "appStoreVersionLocalizations", "id": id, "attributes": ["whatsNew": text]]]
    }

    /// Saves the draft on App Store Connect. Nothing is submitted.
    func saveWhatsNew(localization id: String, _ text: String) async throws {
        _ = try await send(writeRequest("PATCH", "/v1/appStoreVersionLocalizations/\(id)", body: Self.whatsNewBody(localization: id, text: text)))
    }
}

/// Edit a version's What's New in any of its languages and save it as a draft, after a yes.
struct WhatsNewEditor: View {
    let client: ASCClient
    let version: Doc<VersionAttrs>.Item
    @Environment(\.dismiss) private var dismiss
    @State private var locales: [Doc<LocaleText>.Item] = []
    @State private var selected = ""
    @State private var drafts: [String: String] = [:]
    @State private var confirm = false
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false
    static let limit = 4000

    var text: Binding<String> { Binding(get: { drafts[selected] ?? "" }, set: { drafts[selected] = $0 }) }
    var current: Doc<LocaleText>.Item? { locales.first { $0.id == selected } }
    var changed: Bool { (drafts[selected] ?? "") != (current?.attributes.whatsNew ?? "") }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if locales.count > 1 {
                    Picker("Language", selection: $selected) {
                        ForEach(locales) { Text(Locale.current.localizedString(forIdentifier: $0.attributes.locale ?? "") ?? ($0.attributes.locale ?? "")).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                }
                HStack {
                    Text("What's New").font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                    Spacer()
                    Text("\(Self.limit - text.wrappedValue.count)").font(Theme.font(13)).monospacedDigit()
                        .foregroundStyle(text.wrappedValue.count > Self.limit ? Theme.bad : Theme.muted)
                }
                TextEditor(text: text)
                    .font(Theme.font(16))
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if text.wrappedValue.isEmpty {
                            Text("Write your release notes here.").font(Theme.font(16)).foregroundStyle(Theme.muted)
                                .padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                        }
                    }
                    .padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                if let error { Text(error).font(Theme.font(13)).foregroundStyle(Theme.bad) }
                if saved { Label("Saved as a draft on App Store Connect.", systemImage: "checkmark.circle.fill").font(Theme.font(13)).foregroundStyle(Theme.live) }
            }
            .padding(20)
            .background(Theme.bg)
            .navigationTitle("\(version.attributes.versionString ?? "") on \(Theme.platform(version.attributes.platform ?? ""))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Draft") { confirm = true }
                        .disabled(!changed || saving || text.wrappedValue.count > Self.limit)
                }
            }
            .confirmationDialog("Save this What's New on App Store Connect?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Save Draft") { Task { await save() } }
            } message: { Text("It replaces the text there for this language. Nothing is sent to App Review.") }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            locales = try await client.whatsNew(version: version.id)
            for l in locales { drafts[l.id] = l.attributes.whatsNew ?? "" }
            selected = locales.first { $0.attributes.locale == "en-US" }?.id ?? locales.first?.id ?? ""
        } catch { self.error = error.localizedDescription }
    }

    private func save() async {
        guard let current else { return }
        saving = true; defer { saving = false }
        do {
            try await client.saveWhatsNew(localization: current.id, drafts[selected] ?? "")
            saved = true; error = nil
            await load()
        } catch { self.error = error.localizedDescription; saved = false }
    }
}
