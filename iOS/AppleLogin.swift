import SwiftUI
import WebKit

/// App Store Connect has no Sign in with Apple for other apps: its API only takes a key made in
/// Users and Access. So this opens Apple's own page, you sign in there, generate a key and tap
/// Download, and Cyllene picks up the file and IDs so nothing gets typed. Cyllene never sees
/// the password or the two-factor code. Those stay on Apple's page.
struct AppleLoginSheet: View {
    var done: (_ keyID: String, _ issuerID: String, _ pem: String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var problem: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppleLoginWebView { result in
                    switch result {
                    case .success(let key):
                        done(key.keyID, key.issuerID, key.pem)
                        dismiss()
                    case .failure(let error):
                        problem = error.message
                    }
                }
                Text(problem ?? "Sign in, tap Generate API Key, then Download. Cyllene takes it from there.")
                    .font(Theme.display(14))
                    .foregroundStyle(problem == nil ? Theme.muted : Theme.bad)
                    .multilineTextAlignment(.center)
                    .padding(16)
            }
            .navigationTitle("Log in with Apple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct AppleLoginFailure: Error { let message: String }

/// The Issuer ID on the Integrations page, next to its label when the label is there.
func issuerID(inPageText text: String) -> String? {
    let uuid = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
    if let label = text.range(of: "Issuer ID", options: .caseInsensitive),
       let match = text[label.upperBound...].firstMatch(of: uuid) { return String(match.0).lowercased() }
    return text.firstMatch(of: uuid).map { String($0.0).lowercased() }
}

private struct AppleLoginWebView: UIViewRepresentable {
    typealias Key = (keyID: String, issuerID: String, pem: String)
    var finish: (Result<Key, AppleLoginFailure>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(finish: finish) }

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: URL(string: "https://appstoreconnect.apple.com/access/integrations/api")!))
        return web
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKDownloadDelegate {
        let finish: (Result<Key, AppleLoginFailure>) -> Void
        private var file: URL?
        private var fileName = ""
        private weak var web: WKWebView?

        init(finish: @escaping (Result<Key, AppleLoginFailure>) -> Void) { self.finish = finish }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            web = webView
            return action.shouldPerformDownload ? .download : .allow
        }

        func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            web = webView
            let isKey = response.response.suggestedFilename?.hasSuffix(".p8") == true
            return isKey || !response.canShowMIMEType ? .download : .allow
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }

        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }

        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
            fileName = suggestedFilename
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            file = url
            return url
        }

        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            finish(.failure(AppleLoginFailure(message: "The key didn't download. Try again.")))
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let file else { return }
            // The key is secret: it leaves the temporary folder as soon as it is read.
            defer { try? FileManager.default.removeItem(at: file) }
            guard let pem = try? String(contentsOf: file, encoding: .utf8), pem.contains("BEGIN PRIVATE KEY"),
                  let keyID = fileName.firstMatch(of: /AuthKey_([A-Z0-9]+)\.p8/).map({ String($0.1) }) else {
                finish(.failure(AppleLoginFailure(message: "That wasn't an API key file.")))
                return
            }
            web?.evaluateJavaScript("document.body.innerText") { [finish] value, _ in
                guard let text = value as? String, let issuer = issuerID(inPageText: text) else {
                    finish(.failure(AppleLoginFailure(message: "Couldn't find your Issuer ID on the page.")))
                    return
                }
                finish(.success((keyID, issuer, pem)))
            }
        }
    }
}
