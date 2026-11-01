import SwiftUI

// The app list: a split view beside the open app on iPad, a list or a grid on iPhone.
struct AppsView: View {
    let fleet: Fleet
    @State private var query = ""
    @State private var path: [PhoneApp] = []
    @State private var selected: PhoneApp?
    @AppStorage("phoneGrid") private var grid = false
    /// Starred app ids, comma separated. Starred apps sit at the top of every view.
    @AppStorage("starred") private var starredRaw = ""
    @Environment(\.horizontalSizeClass) private var size

    var shown: [PhoneApp] {
        let list = query.isEmpty ? fleet.apps : fleet.apps.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.bundleId.localizedCaseInsensitiveContains(query) }
        return list.filter { starred.contains($0.id) } + list.filter { !starred.contains($0.id) }
    }
    var starred: Set<String> { Set(starredRaw.split(separator: ",").map(String.init)) }

    func toggleStar(_ app: PhoneApp) {
        var s = starred
        if s.contains(app.id) { s.remove(app.id) } else { s.insert(app.id) }
        starredRaw = s.sorted().joined(separator: ",")
    }

    func starButton(_ app: PhoneApp) -> some View {
        let on = starred.contains(app.id)
        return Button { toggleStar(app) } label: { Label(on ? "Unstar" : "Star", systemImage: on ? "star.slash" : "star") }
    }

    var body: some View {
        // iPad and wide windows (10.0): the list beside the open app, like Mail. iPhone keeps the stack.
        if size == .regular {
            NavigationSplitView {
                List(selection: $selected) {
                    if let error = fleet.error { Text(error).foregroundStyle(Theme.bad) }
                    ForEach(shown) { app in AppRow(app: app).tag(app).listRowBackground(Theme.surface).contextMenu { starButton(app) } }
                }
                    .overlay { if fleet.loading && fleet.apps.isEmpty { ProgressView() } }
                    .scrollContentBackground(.hidden).background(Theme.bg)
                    .navigationTitle("Apps")
                    .searchable(text: $query, prompt: "Search Apps")
                    .refreshable { await fleet.load() }
            } detail: {
                if let selected { AppDetail(client: fleet.client, app: selected).id(selected.id) }
                else { Text("Pick an app.").foregroundStyle(Theme.muted).frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.bg) }
            }
        } else { stack }
    }

    var stack: some View {
        NavigationStack(path: $path) {
            Group { if grid { gridView } else { listView } }
            .toolbar { Button { grid.toggle() } label: { Image(systemName: grid ? "list.bullet" : "square.grid.2x2") } }
            .navigationTitle("Apps")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Apps")
            .refreshable { await fleet.load() }
            .navigationDestination(for: PhoneApp.self) { AppDetail(client: fleet.client, app: $0) }
            .onChange(of: fleet.apps) {
                #if DEBUG
                // QA: HERMES_OPEN_APP=<name> opens that app on launch.
                if path.isEmpty, let name = ProcessInfo.processInfo.environment["HERMES_OPEN_APP"], let app = fleet.apps.first(where: { $0.name == name }), app.icon != nil { path = [app] }
                #endif
            }
        }
    }

    /// The fleet grid from the Mac (5.0), two cards a row on a phone.
    var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(shown) { app in
                    NavigationLink(value: app) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Tile(name: app.name, icon: app.icon, size: 32); Text(app.name).font(Theme.font(14, .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                                if starred.contains(app.id) { Spacer(minLength: 0); Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(Theme.pending) }
                            }
                            ForEach(app.versions, id: \.platform) { StateLine(state: $0.state, text: "\(Theme.platform($0.platform)) \($0.version)") }
                        }
                        .padding(12).frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contextMenu { starButton(app) }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .overlay { if fleet.loading && fleet.apps.isEmpty { ProgressView() } }
    }

    func row(_ app: PhoneApp) -> some View {
        NavigationLink(value: app) { AppRow(app: app) }
            .listRowBackground(Theme.surface)
            .swipeActions(edge: .leading) { starButton(app).tint(Theme.pending) }
            .contextMenu { starButton(app) }
    }

    var listView: some View {
            List {
                if let error = fleet.error { Text(error).foregroundStyle(Theme.bad) }
                let top = shown.filter { starred.contains($0.id) }, rest = shown.filter { !starred.contains($0.id) }
                if !top.isEmpty {
                    Section("Starred") { ForEach(top) { row($0) } }
                }
                Section(top.isEmpty ? "" : "All apps") { ForEach(rest) { row($0) } }
            }
            .overlay { if fleet.loading && fleet.apps.isEmpty { ProgressView() } }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
    }
}
