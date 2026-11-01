import SwiftUI

// Share a "new version out" card (10.13): the newest live version on each platform gets a share button with a square image card.

struct VersionCard: View {
    let name: String, version: String, mac: Bool
    let icon: UIImage?

    var body: some View {
        VStack(spacing: 18) {
            if let icon { Image(uiImage: icon).resizable().frame(width: 160, height: 160).clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous)) }
            Text(name).font(Theme.font(44, .semibold)).foregroundStyle(.white)
            Text("Version \(version) is out").font(Theme.font(26)).foregroundStyle(.white.opacity(0.7))
            Text(mac ? "On the Mac App Store" : "On the App Store").font(Theme.font(20, .semibold)).foregroundStyle(Theme.accent).padding(.top, 8)
        }
        .frame(width: 600, height: 600)
        .background(Color(red: 0.05, green: 0.06, blue: 0.09))
        .environment(\.colorScheme, .dark)  // the card is always dark, so the accent takes its bright variant
    }
}

struct ShareVersionButton: View {
    let name: String, version: String, appID: String, mac: Bool
    let icon: URL?
    @State private var card: Image?

    var body: some View {
        Group {
            if let card {
                ShareLink(item: card, message: Text("\(name) \(version) is out: https://apps.apple.com/app/id\(appID)"),
                          preview: SharePreview("\(name) \(version)", image: card)) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.accent)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Share \(name) \(version)")
            } else {
                Color.clear.frame(width: 24, height: 24)  // an empty Group never appears, so its task would never run
            }
        }
        .task {
            // The icon is fetched first: ImageRenderer draws once and would miss an AsyncImage.
            let ui = await icon.asyncFlatMap { try? await URLSession.shared.data(from: $0).0 }.flatMap(UIImage.init(data:))
            let r = ImageRenderer(content: VersionCard(name: name, version: version, mac: mac, icon: ui))
            r.scale = 2
            guard let img = r.uiImage else { return }
            card = Image(uiImage: img)
            // QA: HERMES_SHARE=1 writes the card to Caches/card.png to look at.
            if ProcessInfo.processInfo.environment["HERMES_SHARE"] != nil {
                try? img.pngData()?.write(to: URL.cachesDirectory.appendingPathComponent("card.png"))
            }
        }
    }
}

extension Optional {
    func asyncFlatMap<U>(_ f: (Wrapped) async -> U?) async -> U? {
        guard let self else { return nil }
        return await f(self)
    }
}
