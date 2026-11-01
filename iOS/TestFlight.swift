import SwiftUI

// TestFlight on the phone: an app's beta groups, the testers in each, and adding a tester by email (asks first).

struct BetaGroupAttrs: Decodable { let name: String?; let isInternalGroup: Bool?; let publicLinkEnabled: Bool?; let publicLink: String? }
struct BetaTesterAttrs: Decodable { let firstName: String?; let lastName: String?; let email: String?; let state: String? }

extension ASCClient {
    func betaGroups(_ app: String) async throws -> [Doc<BetaGroupAttrs>.Item] {
        try await decode(Doc<BetaGroupAttrs>.self, "/v1/apps/\(app)/betaGroups",
                         ["fields[betaGroups]": "name,isInternalGroup,publicLinkEnabled,publicLink", "limit": "50"]).data
    }

    func betaTesters(group: String) async throws -> [Doc<BetaTesterAttrs>.Item] {
        try await decode(Doc<BetaTesterAttrs>.self, "/v1/betaGroups/\(group)/betaTesters",
                         ["fields[betaTesters]": "firstName,lastName,email,state", "limit": "200"]).data
    }

    static func addTesterBody(email: String, group: String) -> [String: Any] {
        ["data": ["type": "betaTesters", "attributes": ["email": email],
                  "relationships": ["betaGroups": ["data": [["type": "betaGroups", "id": group]]]]]]
    }

    /// Creates the tester in that group; Apple emails them the invite.
    func addTester(email: String, group: String) async throws {
        _ = try await send(writeRequest("POST", "/v1/betaTesters", body: Self.addTesterBody(email: email, group: group)))
    }
}

struct BetaGroupsList: View {
    let client: ASCClient
    let app: String
    @State private var groups: [Doc<BetaGroupAttrs>.Item]?
    @State private var error: String?
    @State private var opened: String?

    var body: some View {
        Group {
            if let error { Text(error).foregroundStyle(Theme.bad) }
            else if let groups, groups.isEmpty { Text("No TestFlight groups yet.").foregroundStyle(Theme.muted) }
            else if groups == nil { ProgressView() }
            ForEach(groups ?? []) { g in
                NavigationLink { BetaGroupView(client: client, group: g) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(g.attributes.name ?? "Group").font(Theme.font(16, .semibold))
                        Text(g.attributes.isInternalGroup == true ? "Internal" : g.attributes.publicLinkEnabled == true ? "External · public link on" : "External")
                            .font(Theme.font(13)).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
        .navigationDestination(item: $opened) { id in if let g = groups?.first(where: { $0.id == id }) { BetaGroupView(client: client, group: g) } }
        .task {
            do { groups = try await client.betaGroups(app); error = nil } catch { self.error = error.localizedDescription }
            // QA: HERMES_OPEN_GROUP=1 opens the last group on launch.
            if ProcessInfo.processInfo.environment["HERMES_OPEN_GROUP"] != nil { opened = groups?.last?.id }
        }
    }
}

struct BetaGroupView: View {
    let client: ASCClient
    let group: Doc<BetaGroupAttrs>.Item
    @State private var testers: [Doc<BetaTesterAttrs>.Item] = []
    @State private var email = ""
    @State private var confirm = false
    @State private var busy = false
    @State private var error: String?

    private var valid: Bool { email.contains("@") && email.contains(".") && !email.contains(" ") }

    var body: some View {
        List {
            if let link = group.attributes.publicLink, group.attributes.publicLinkEnabled == true, let url = URL(string: link) {
                Section("Public link") { ShareLink(item: url) { Label(link, systemImage: "link") } }.listRowBackground(Theme.surface)
            }
            Section("Add a tester") {
                TextField("Email", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button(busy ? "Adding…" : "Add to \(group.attributes.name ?? "group")") { confirm = true }.disabled(!valid || busy)
                if let error { Text(error).foregroundStyle(Theme.bad) }
            }
            .listRowBackground(Theme.surface)
            Section("Testers (\(testers.count))") {
                if testers.isEmpty { Text("No testers in this group.").foregroundStyle(Theme.muted) }
                ForEach(testers) { t in
                    let a = t.attributes, name = [a.firstName, a.lastName].compactMap { $0 }.joined(separator: " ")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? (a.email ?? "Tester") : name).font(Theme.font(16, .semibold))
                        Text([a.email, a.state.map(Theme.words)].compactMap { $0 }.joined(separator: " · ")).font(Theme.font(13)).foregroundStyle(Theme.muted)
                    }
                }
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(group.attributes.name ?? "Group")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .confirmationDialog("Invite \(email) to \(group.attributes.name ?? "this group") on TestFlight?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Invite") { Task { await add() } }
        }
    }

    private func load() async {
        do { testers = try await client.betaTesters(group: group.id); error = nil } catch { self.error = error.localizedDescription }
    }

    private func add() async {
        busy = true; defer { busy = false }
        do { try await client.addTester(email: email.trimmingCharacters(in: .whitespaces), group: group.id); email = ""; await load() }
        catch { self.error = error.localizedDescription }
    }
}
