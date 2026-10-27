import SwiftUI

/// Categorías seleccionables en la barra lateral
public enum SidebarSelection: Hashable {
    case all
    case favorites
    case recent
    case problems
    case manufacturer(String)
    case year(String)
    case settings
    case about
}

/// Barra lateral moderna y colapsable para macOS
public struct SidebarView: View {
    @Binding public var selection: SidebarSelection
    public let allGames: [Game]
    public let onOpenSettings: () -> Void
    public let onOpenAbout: () -> Void
    
    public init(
        selection: Binding<SidebarSelection>,
        allGames: [Game],
        onOpenSettings: @escaping () -> Void,
        onOpenAbout: @escaping () -> Void
    ) {
        self._selection = selection
        self.allGames = allGames
        self.onOpenSettings = onOpenSettings
        self.onOpenAbout = onOpenAbout
    }
    
    // Cálculos de datos reales
    private var favoritesCount: Int {
        allGames.filter { $0.isFavorite }.count
    }
    
    private var recentCount: Int {
        allGames.filter { $0.lastPlayed != nil }.count
    }
    
    private var problemsCount: Int {
        allGames.filter { $0.status == .missingFiles || $0.status == .fileNotFound }.count
    }
    
    private var topManufacturers: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for game in allGames {
            if let mfg = game.manufacturer, !mfg.isEmpty {
                counts[mfg, default: 0] += 1
            }
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }
    
    private var availableYears: [(year: String, count: Int)] {
        var counts: [String: Int] = [:]
        for game in allGames {
            if let y = game.year, !y.isEmpty {
                counts[y, default: 0] += 1
            }
        }
        return counts.map { (year: $0.key, count: $0.value) }
            .sorted { $0.year > $1.year }
            .prefix(8)
            .map { $0 }
    }
    
    public var body: some View {
        List {
            Section("BIBLIOTECA") {
                sidebarRow(
                    title: "Todos los juegos",
                    icon: "square.grid.2x2",
                    count: allGames.count,
                    target: .all
                )
                sidebarRow(
                    title: "Favoritos",
                    icon: "star.fill",
                    iconColor: ArcadeTheme.accentGold,
                    count: favoritesCount,
                    target: .favorites
                )
                sidebarRow(
                    title: "Jugados recientemente",
                    icon: "clock.arrow.circlepath",
                    count: recentCount,
                    target: .recent
                )
                if problemsCount > 0 {
                    sidebarRow(
                        title: "Con problemas",
                        icon: "exclamationmark.triangle.fill",
                        iconColor: ArcadeTheme.statusWarning,
                        count: problemsCount,
                        target: .problems
                    )
                }
            }
            
            if !topManufacturers.isEmpty {
                Section("POR FABRICANTE") {
                    ForEach(topManufacturers, id: \.name) { item in
                        sidebarRow(
                            title: item.name,
                            icon: "building.2",
                            count: item.count,
                            target: .manufacturer(item.name)
                        )
                    }
                }
            }
            
            if !availableYears.isEmpty {
                Section("POR AÑO") {
                    ForEach(availableYears, id: \.year) { item in
                        sidebarRow(
                            title: item.year,
                            icon: "calendar",
                            count: item.count,
                            target: .year(item.year)
                        )
                    }
                }
            }
            
            Section("APLICACIÓN") {
                Button(action: onOpenSettings) {
                    Label("Ajustes", systemImage: "gearshape")
                        .foregroundColor(ArcadeTheme.textPrimary)
                }
                .buttonStyle(.plain)
                
                Button(action: onOpenAbout) {
                    Label("Acerca de", systemImage: "info.circle")
                        .foregroundColor(ArcadeTheme.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, idealWidth: 220)
    }
    
    private func sidebarRow(
        title: String,
        icon: String,
        iconColor: Color = ArcadeTheme.accent,
        count: Int,
        target: SidebarSelection
    ) -> some View {
        Button(action: { selection = target }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 18)
                Text(title)
                    .foregroundColor(selection == target ? .white : ArcadeTheme.textPrimary)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            selection == target ?
            ArcadeTheme.surfaceRaised :
            Color.clear
        )
    }
}
