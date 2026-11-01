import BackgroundTasks
import UserNotifications

/// A notification when one of your apps moves in App Review: submitted, in review, approved, rejected.
/// iOS wakes Cyllene about every 15 minutes in the background to check; there is no server.
enum ReviewWatch {
    static let task = "com.nulljosh.hermes.refresh"

    /// "appId|platform" to review state.
    static func snapshot(_ apps: [PhoneApp]) -> [String: String] {
        var out: [String: String] = [:]
        for a in apps { for v in a.versions { out["\(a.id)|\(v.platform)"] = v.state } }
        return out
    }

    /// Only real moves count: a version seen for the first time is not a change.
    static func changes(from old: [String: String], to new: [String: String]) -> [(key: String, from: String, to: String)] {
        new.compactMap { k, s in old[k].flatMap { $0 != s ? (k, $0, s) : nil } }.sorted { $0.key < $1.key }
    }

    static func words(_ state: String) -> String { state.lowercased().replacingOccurrences(of: "_", with: " ") }

    /// Called after every load. The first load only records; later loads notify on what moved.
    static func check(_ apps: [PhoneApp]) {
        let now = snapshot(apps), d = UserDefaults.standard
        defer { d.set(now, forKey: "lastStates") }
        guard d.bool(forKey: "notifyReview"), let old = d.dictionary(forKey: "lastStates") as? [String: String] else { return }
        for c in changes(from: old, to: now) {
            let parts = c.key.split(separator: "|").map(String.init)
            let n = UNMutableNotificationContent()
            n.title = "\(apps.first { $0.id == parts.first }?.name ?? "An app") on \(Theme.platform(parts.last ?? ""))"
            n.body = "\(words(c.from).capitalized) to \(words(c.to))."
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: c.key + c.to, content: n, trigger: nil))
        }
    }

    static func schedule() {
        guard UserDefaults.standard.bool(forKey: "notifyReview") else { return }
        let r = BGAppRefreshTaskRequest(identifier: task)
        r.earliestBeginDate = Date(timeIntervalSinceNow: 900)
        try? BGTaskScheduler.shared.submit(r)
    }

    /// The background wake: reload the account, which runs `check`, then book the next wake.
    static func refresh() async {
        schedule()
        guard let key = KeyStore.load() else { return }
        await Fleet(client: ASCClient(key: key)).load()
    }
}
