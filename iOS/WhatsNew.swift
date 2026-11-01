import SwiftUI
import Translation

struct LocaleText: Decodable {
    let locale: String?
    let whatsNew: String?
    let description: String?
    let promotionalText: String?
    let keywords: String?
    func value(_ f: ListingField) -> String? {
        switch f { case .whatsNew: whatsNew; case .description: description; case .promotionalText: promotionalText; case .keywords: keywords }
    }
}

/// The listing text a version carries per language, with App Store Connect's length limits.
enum ListingField: String, CaseIterable, Identifiable {
    case whatsNew, description, promotionalText, keywords
    var id: String { rawValue }
    var title: String { switch self { case .whatsNew: "What's New"; case .description: "Description"; case .promotionalText: "Promotional Text"; case .keywords: "Keywords" } }
    var short: String { switch self { case .whatsNew: "What's New"; case .description: "Description"; case .promotionalText: "Promo"; case .keywords: "Keywords" } }
    var limit: Int { switch self { case .whatsNew, .description: 4000; case .promotionalText: 170; case .keywords: 100 } }
}

extension ASCClient {
    func whatsNew(version id: String) async throws -> [Doc<LocaleText>.Item] {
        try await decode(Doc<LocaleText>.self, "/v1/appStoreVersions/\(id)/appStoreVersionLocalizations",
                         ["fields[appStoreVersionLocalizations]": "locale,whatsNew,description,promotionalText,keywords", "limit": "50"]).data
    }

    static func listingBody(localization id: String, _ attributes: [String: String]) -> [String: Any] {
        ["data": ["type": "appStoreVersionLocalizations", "id": id, "attributes": attributes]]
    }

    /// Saves the changed listing text for one language as a draft on App Store Connect. Nothing is submitted.
    func saveListing(localization id: String, _ attributes: [String: String]) async throws {
        _ = try await send(writeRequest("PATCH", "/v1/appStoreVersionLocalizations/\(id)", body: Self.listingBody(localization: id, attributes)))
    }
}

/// Edit a version's What's New, description, promotional text and keywords in any of its languages, translate the
/// English into the rest on the device, and save it all as a draft after a yes.
struct WhatsNewEditor: View {
    let client: ASCClient
    let version: Doc<VersionAttrs>.Item
    /// Apple has no What's New on an app's first version for a platform, so the checklist leaves it out there.
    var fields: [ListingField] = ListingField.allCases
    @Environment(\.dismiss) private var dismiss
    @State private var locales: [Doc<LocaleText>.Item] = []
    @State private var selected = ""
    @State private var field: ListingField = .whatsNew
    /// Keyed "field|localization id".
    @State private var drafts: [String: String] = [:]
    @State private var confirm = false
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false

    func key(_ f: ListingField, _ id: String) -> String { "\(f.rawValue)|\(id)" }
    var text: Binding<String> { Binding(get: { drafts[key(field, selected)] ?? "" }, set: { drafts[key(field, selected)] = $0 }) }
    /// Each language's changed fields, against what App Store Connect has.
    var changes: [String: [String: String]] {
        var out: [String: [String: String]] = [:]
        for l in locales { for f in ListingField.allCases {
            let d = drafts[key(f, l.id)] ?? ""
            if d != (l.attributes.value(f) ?? "") { out[l.id, default: [:]][f.rawValue] = d }
        } }
        return out
    }
    var changedIDs: [String] { Array(changes.keys) }
    var tooLong: Bool { locales.contains { l in ListingField.allCases.contains { (drafts[key($0, l.id)] ?? "").count > $0.limit } } }
    var english: Doc<LocaleText>.Item? { locales.first { $0.attributes.locale == "en-US" } ?? locales.first { $0.attributes.locale?.hasPrefix("en") == true } }
    var englishText: String { english.map { drafts[key(field, $0.id)] ?? "" } ?? "" }
    @State private var translating = false
    @State private var note: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Text", selection: $field) { ForEach(fields) { Text($0.short).tag($0) } }
                    .pickerStyle(.segmented)
                if locales.count > 1 {
                    Picker("Language", selection: $selected) {
                        ForEach(locales) { Text(Locale.current.localizedString(forIdentifier: $0.attributes.locale ?? "") ?? ($0.attributes.locale ?? "")).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                }
                if #available(iOS 18, *), locales.count > 1, english != nil {
                    Button(translating ? "Translating…" : "Translate English into every language", systemImage: "translate") { translating = true }
                        .font(Theme.font(14, .semibold)).foregroundStyle(Theme.accent).buttonStyle(.borderless)
                        .disabled(translating || englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .modifier(TranslateAll(run: $translating, source: englishText, targets: locales.filter { $0.id != english?.id }.map { ($0.id, $0.attributes.locale ?? "") }) { id, text in
                            drafts[key(field, id)] = field == .keywords ? String(text.prefix(field.limit)) : text
                        } done: { n in note = n })
                }
                if let note { Text(note).font(Theme.font(13)).foregroundStyle(Theme.muted) }
                HStack {
                    Text(field.title).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                    Spacer()
                    Text("\(field.limit - text.wrappedValue.count)").font(Theme.font(13)).monospacedDigit()
                        .foregroundStyle(text.wrappedValue.count > field.limit ? Theme.bad : Theme.muted)
                }
                TextEditor(text: text)
                    .font(Theme.font(16))
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if text.wrappedValue.isEmpty {
                            Text(field == .whatsNew ? "Write your release notes here." : field == .keywords ? "Comma separated, no spaces after commas." : "Write it here.").font(Theme.font(16)).foregroundStyle(Theme.muted)
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
                        .disabled(changedIDs.isEmpty || saving || tooLong)
                }
            }
            .confirmationDialog(changedIDs.count == 1 ? "Save these changes on App Store Connect?" : "Save changes in \(changedIDs.count) languages on App Store Connect?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Save Draft") { Task { await save() } }
            } message: { Text("It replaces the text there for \(changedIDs.count == 1 ? "this language" : "those languages"). Nothing is sent to App Review.") }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            locales = try await client.whatsNew(version: version.id)
            for l in locales { for f in ListingField.allCases { drafts[key(f, l.id)] = l.attributes.value(f) ?? "" } }
            selected = locales.first { $0.attributes.locale == "en-US" }?.id ?? locales.first?.id ?? ""
            if !fields.contains(field), let f = fields.first { field = f }
            // QA: HERMES_TRANSLATE=1 runs Translate on open.
            if ProcessInfo.processInfo.environment["HERMES_TRANSLATE"] != nil { translating = true }
        } catch { self.error = error.localizedDescription }
    }

    private func save() async {
        saving = true; defer { saving = false }
        do {
            for (id, attrs) in changes { try await client.saveListing(localization: id, attrs) }
            saved = true; error = nil; note = nil
            await load()
        } catch { self.error = error.localizedDescription; saved = false }
    }
}

/// Translates the English What's New into each listing language with Apple's on-device models, one language at a time.
/// English variants (en-GB, en-AU) get the English text as is; languages Apple cannot translate are skipped and named.
@available(iOS 18, *)
struct TranslateAll: ViewModifier {
    @Binding var run: Bool
    let source: String
    let targets: [(id: String, locale: String)]
    let fill: (String, String) -> Void
    let done: (String) -> Void
    @State private var queue: [(id: String, locale: String)] = []
    @State private var config: TranslationSession.Configuration?
    @State private var skipped: [String] = []
    @State private var count = 0

    static let en = Locale.Language(identifier: "en")

    func body(content: Content) -> some View {
        content
            .onChange(of: run, initial: true) { _, on in if on { Task { await start() } } }
            .translationTask(config) { session in
                guard let t = queue.first else { return }
                do { fill(t.id, try await session.translate(source).targetText); count += 1 }
                catch { skipped.append(Self.name(t.locale)) }
                queue.removeFirst()
                await next()
            }
    }

    private func start() async {
        queue = []; skipped = []; count = 0
        let avail = LanguageAvailability()
        for t in targets {
            if t.locale.hasPrefix("en") { fill(t.id, source); count += 1; continue }
            if await avail.status(from: Self.en, to: Locale.Language(identifier: t.locale)) == .unsupported { skipped.append(Self.name(t.locale)) }
            else { queue.append(t) }
        }
        await next()
    }

    private func next() async {
        guard let t = queue.first else {
            config = nil; run = false
            let missed = skipped.joined(separator: ", ")
            done(count == 0 ? "This iPhone could not translate into \(missed). Download them in the Translate app, then try again."
                 : "Filled \(count) language\(count == 1 ? "" : "s"). Read them over, then Save Draft." + (skipped.isEmpty ? "" : " Skipped: \(missed)."))
            return
        }
        config = .init(source: Self.en, target: Locale.Language(identifier: t.locale))
    }

    static func name(_ id: String) -> String { Locale.current.localizedString(forIdentifier: id) ?? id }
}
