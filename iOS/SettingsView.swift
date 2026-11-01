import SwiftUI
import UserNotifications

struct SettingsView: View {
    let fleet: Fleet
    var onSwitch: (ASCKey) -> Void
    var onDisconnect: () -> Void
    @State private var adding = false
    @AppStorage("onboarded") private var onboarded = true
    @AppStorage("signature") private var signature = ""
    @AppStorage("appLock") private var appLock = false
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("notifyReview") private var notifyReview = false
    @State private var confirm = false

    func masked(_ s: String) -> String { String(repeating: "•", count: max(0, min(s.count, 12) - 4)) + s.suffix(4) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Key ID", value: masked(fleet.client.key.keyID))
                    LabeledContent("Issuer", value: masked(fleet.client.key.issuerID))
                    LabeledContent("Apps", value: "\(fleet.apps.count)")
                    Button("Disconnect key", role: .destructive) { confirm = true }
                } header: { Text("App Store Connect") } footer: { Text("Your key lives in your Keychain and syncs only through iCloud Keychain.") }
                Section {
                    ForEach(KeyStore.all(), id: \.keyID) { k in
                        Button { if k != fleet.client.key { onSwitch(k) } } label: {
                            HStack {
                                Text("Key \(masked(k.keyID))").foregroundStyle(.primary)
                                Spacer()
                                if k == fleet.client.key { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                            }
                        }
                    }
                    Button("Add account") { adding = true }
                } header: { Text("Accounts") } footer: { Text("Each App Store Connect team needs its own key. Tap one to switch.") }
                Section {
                    LabeledContent("Changes", value: "Ask first")
                    TextField("Reply signature", text: $signature)
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    Button("Show the intro again") { onboarded = false }
                } header: { Text("Cyllene") }
                Section {
                    Toggle("App Lock", isOn: $appLock)
                    Toggle("Review notifications", isOn: $notifyReview)
                        .onChange(of: notifyReview) { _, on in
                            guard on else { return }
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { ok, _ in
                                DispatchQueue.main.async { if ok { ReviewWatch.schedule() } else { notifyReview = false } }
                            }
                        }
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                    }
                } header: { Text("Privacy and Appearance") } footer: { Text("App Lock asks for Face ID or your passcode each time Cyllene opens. Review notifications tell you when an app is approved, rejected or moves in review; Cyllene checks about every 15 minutes.") }
                Section {
                    Link("Docs", destination: URL(string: "https://cyllene.jaybulb.com/docs")!)
                    Link("Send feedback", destination: URL(string: "mailto:trommatic@icloud.com?subject=Cyllene%20iOS")!)
                    Link("Source on GitHub", destination: URL(string: "https://github.com/nulljosh/cyllene")!)
                    Link("Privacy", destination: URL(string: "https://cyllene.jaybulb.com/privacy")!)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Settings")
            .sheet(isPresented: $adding) { KeyView { adding = false; onSwitch($0) } }
            .confirmationDialog("Disconnect this key?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Disconnect", role: .destructive, action: onDisconnect)
            } message: { Text("It is removed from this device's Keychain. Your account is not touched.") }
        }
    }
}

/// The average and a five-bar histogram over the reviews loaded, the way the App Store shows ratings.
struct RatingsSummary: View {
    let ratings: [Int]
    var average: Double { ratings.isEmpty ? 0 : Double(ratings.reduce(0, +)) / Double(ratings.count) }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 0) {
                Text(average, format: .number.precision(.fractionLength(1))).font(Theme.display(44))
                Text("out of 5").font(Theme.font(13)).foregroundStyle(Theme.muted)
            }
            VStack(alignment: .trailing, spacing: 3) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    HStack(spacing: 8) {
                        Text(String(repeating: "★", count: star)).font(.system(size: 8)).foregroundStyle(Theme.muted)
                        GeometryReader { g in
                            Capsule().fill(Theme.muted.opacity(0.2))
                                .overlay(alignment: .leading) {
                                    Capsule().fill(Theme.text.opacity(0.8)).frame(width: g.size.width * share(star))
                                }
                        }
                        .frame(height: 4)
                    }
                }
                Text(ratings.count == 1 ? "1 rating" : "\(ratings.count) ratings").font(Theme.font(12)).foregroundStyle(Theme.muted).padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Average \(average, specifier: "%.1f") out of 5 from \(ratings.count) ratings")
    }

    private func share(_ star: Int) -> CGFloat {
        ratings.isEmpty ? 0 : CGFloat(ratings.filter { $0 == star }.count) / CGFloat(ratings.count)
    }
}
