import CoreText
import LocalAuthentication
import Security
import SwiftUI

// Hermes on iPhone: the app list and one app's versions, builds and reviews, read only, straight from Apple's API.

@main
struct HermesPhoneApp: App {
    init() {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        KeyStore.importDebugKey()
    }

    var body: some Scene {
        WindowGroup { PhoneRoot() }
            .backgroundTask(.appRefresh(ReviewWatch.task)) { await ReviewWatch.refresh() }
    }
}

/// The API key lives in the Keychain, synced between your devices by iCloud Keychain and nowhere else.
enum KeyStore {
    private static let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.nulljosh.hermes.asc",
                                              kSecAttrAccount as String: "key", kSecAttrSynchronizable as String: kCFBooleanTrue!]

    static func load() -> ASCKey? {
        var q = base; q[kSecReturnData as String] = true
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return try? JSONDecoder().decode(ASCKey.self, from: d)
    }

    /// Every account this device knows, kept beside the active key so switching never asks for the .p8 again.
    private static let listQuery: [String: Any] = base.merging([kSecAttrAccount as String: "keys"]) { $1 }

    static func all() -> [ASCKey] {
        var q = listQuery; q[kSecReturnData as String] = true
        var out: AnyObject?
        if SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data,
           let keys = try? JSONDecoder().decode([ASCKey].self, from: d), !keys.isEmpty { return keys }
        return load().map { [$0] } ?? []
    }

    private static func saveAll(_ keys: [ASCKey]) {
        SecItemDelete(listQuery as CFDictionary)
        var q = listQuery
        q[kSecValueData as String] = try? JSONEncoder().encode(keys)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(q as CFDictionary, nil)
    }

    static func forget(_ key: ASCKey) { saveAll(all().filter { $0 != key }) }

    static func save(_ key: ASCKey) {
        var keys = all()
        if !keys.contains(key) { keys.append(key); saveAll(keys) }
        delete()
        var q = base
        q[kSecValueData as String] = try? JSONEncoder().encode(key)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(q as CFDictionary, nil)
    }

    static func delete() { SecItemDelete(base as CFDictionary) }

    /// Debug builds only: `simctl launch` can pass a key in the environment for testing. Release builds ignore it.
    static func importDebugKey() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        guard let id = env["HERMES_KEY_ID"], let issuer = env["HERMES_ISSUER_ID"], let b64 = env["HERMES_KEY_PEM_B64"],
              let pemData = Data(base64Encoded: b64) else { return }
        save(ASCKey(keyID: id, issuerID: issuer, pem: String(decoding: pemData, as: UTF8.self)))
        #endif
    }
}

/// Debug-only QA switch: HERMES_SCREEN=onboarding|status|settings opens that screen on launch.
let qaScreen: String = {
    #if DEBUG
    return ProcessInfo.processInfo.environment["HERMES_SCREEN"] ?? ""
    #else
    return ""
    #endif
}()

struct PhoneRoot: View {
    @State private var key = qaScreen == "onboarding" ? nil : KeyStore.load()
    @State private var fleet: Fleet?
    @State private var splashDone = false
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("appLock") private var appLock = false
    @AppStorage("appearance") private var appearance = "system"
    @State private var locked = UserDefaults.standard.bool(forKey: "appLock")
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            Group {
                if let fleet {
                    MainTabs(fleet: fleet, onSwitch: use) {
                        KeyStore.forget(fleet.client.key)
                        if let next = KeyStore.all().first { use(next) } else { KeyStore.delete(); key = nil; self.fleet = nil }
                    }
                    .id(fleet.client.key.keyID + fleet.client.key.issuerID)
                }
                else if !onboarded || qaScreen == "onboarding" { OnboardingView { withAnimation { onboarded = true } } }
                else { KeyView { use($0) } }
            }
            if appLock && locked && splashDone { LockView { locked = false }.zIndex(2) }
            if !splashDone {
                SplashView { withAnimation(.easeOut(duration: 0.25)) { splashDone = true } }.transition(.opacity).zIndex(1)
            }
        }
        .onChange(of: phase) { _, p in if p == .background { locked = true; ReviewWatch.schedule() } }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .tint(Theme.accent)
        .font(Theme.font(17))
        .onAppear { if let key, fleet == nil { fleet = Fleet(client: ASCClient(key: key)) } }
    }

    private func use(_ k: ASCKey) { KeyStore.save(k); key = k; fleet = Fleet(client: ASCClient(key: k)) }
}

struct MainTabs: View {
    let fleet: Fleet
    var onSwitch: (ASCKey) -> Void
    var onDisconnect: () -> Void
    @State private var tab = qaScreen == "status" ? 1 : qaScreen == "settings" ? 2 : 0

    var body: some View {
        TabView(selection: $tab) {
            AppsView(fleet: fleet).tabItem { Label("Apps", systemImage: "square.grid.2x2") }.tag(0)
            StatusView(fleet: fleet).tabItem { Label("Status", systemImage: "circle.dotted.circle") }.tag(1)
            SettingsView(fleet: fleet, onSwitch: onSwitch, onDisconnect: onDisconnect).tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
        }
        .task { if fleet.apps.isEmpty { await fleet.load() } }
    }
}

/// App Lock: Face ID, Touch ID or the device passcode before the app shows anything. Locks again when it leaves the screen.
struct LockView: View {
    var unlocked: () -> Void
    @State private var failed = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.system(size: 44)).foregroundStyle(Theme.accent)
            Text("Cyllene is locked").font(Theme.font(22, .semibold))
            Group {
                if #available(iOS 26, *) { Button("Unlock") { unlock() }.buttonStyle(.glassProminent) }
                else { Button("Unlock") { unlock() }.buttonStyle(.borderedProminent) }
            }
            .controlSize(.large)
            if failed { Text("Not unlocked. Try again.").font(Theme.font(15)).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .task { unlock() }
    }

    private func unlock() {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { unlocked(); return }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Cyllene") { ok, _ in
            DispatchQueue.main.async { if ok { unlocked() } else { failed = true } }
        }
    }
}
