import SwiftUI
import UniformTypeIdentifiers

/// Cyllene's settings as one JSON file: appearance, notifications, read-only mode, signatures, vendor number,
/// starred apps and view choices. Never a key, issuer or account profile; those stay in the Keychain and
/// move with `asc auth export-to-config`.
enum SetupFile {
    static let keys = ["appearance", "notifyReview", "readOnly", "signature", "replySignature", "vendorNumber",
                       "phoneGrid", "fleetView", "starred", "archivedEvents", "appLock"]

    /// The settings that are set on this device, as pretty JSON.
    static func export(_ defaults: UserDefaults = .standard) -> Data {
        var out: [String: Any] = ["cylleneSetup": 1]
        for k in keys { if let v = defaults.object(forKey: k) as? NSObject, v is String || v is NSNumber { out[k] = v } }
        return (try? JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    /// Applies a file made by `export`. Only known keys of the right kind are read; returns how many were set,
    /// or nil when the file is not a Cyllene setup file.
    @discardableResult
    static func apply(_ data: Data, to defaults: UserDefaults = .standard) -> Int? {
        guard let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any], d["cylleneSetup"] != nil else { return nil }
        var n = 0
        for k in keys {
            if let s = d[k] as? String, s.count <= 20_000 { defaults.set(s, forKey: k); n += 1 }
            else if let b = d[k] as? NSNumber { defaults.set(b, forKey: k); n += 1 }
        }
        return n
    }
}

/// The JSON file for fileExporter.
struct SetupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Export and Import buttons for a settings screen.
struct SetupFileButtons: View {
    @State private var exporting = false
    @State private var importing = false
    @State private var note: String?

    var body: some View {
        Button("Export Settings…") { exporting = true }
            .fileExporter(isPresented: $exporting, document: SetupDocument(data: SetupFile.export()), contentType: .json,
                          defaultFilename: "Cyllene Settings") { result in
                if case .success = result { note = "Settings saved. Keys are never included." }
            }
        Button("Import Settings…") { importing = true }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), let n = SetupFile.apply(data) { note = "\(n) settings imported." }
                else { note = "That file is not a Cyllene settings file." }
            }
        if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
    }
}
