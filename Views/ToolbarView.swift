import SwiftUI

/// Barra de herramientas superior con controles de búsqueda, importación, ordenación y vistas
public struct ToolbarView: View {
    @Binding public var searchText: String
    @Binding public var viewMode: LibraryViewMode
    @Binding public var sortField: SortField
    @Binding public var sortAscending: Bool
    public let totalGames: Int
    public let mameVersion: String?
    public let onAddGames: () -> Void
    public let onRescanLibrary: () -> Void
    public let onDownloadMissingCovers: () -> Void
    public let onOpenSettings: () -> Void
    
    public init(
        searchText: Binding<String>,
        viewMode: Binding<LibraryViewMode>,
        sortField: Binding<SortField>,
        sortAscending: Binding<Bool>,
        totalGames: Int,
        mameVersion: String?,
        onAddGames: @escaping () -> Void,
        onRescanLibrary: @escaping () -> Void,
        onDownloadMissingCovers: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self._searchText = searchText
        self._viewMode = viewMode
        self._sortField = sortField
        self._sortAscending = sortAscending
        self.totalGames = totalGames
        self.mameVersion = mameVersion
        self.onAddGames = onAddGames
        self.onRescanLibrary = onRescanLibrary
        self.onDownloadMissingCovers = onDownloadMissingCovers
        self.onOpenSettings = onOpenSettings
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Botón Agregar juegos
            Button(action: onAddGames) {
                Label("Agregar juegos", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(ArcadeTheme.accent)
            .help("Importar archivos ROM (.zip o .7z) o carpetas completas")
            
            // Botón Actualizar/Analizar biblioteca
            Button(action: onRescanLibrary) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .help("Volver a analizar y verificar la existencia de los archivos ROM")
            
            // Botón Descargar carátulas en línea
            Button(action: onDownloadMissingCovers) {
                Image(systemName: "photo.badge.arrow.down")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .help("Obtener carátulas en línea (Arcade Database / Libretro) para juegos sin imagen")
            
            // Selector de Vista (Cuadrícula / Lista)
            Picker("Vista", selection: $viewMode) {
                Image(systemName: "square.grid.2x2")
                    .tag(LibraryViewMode.grid)
                    .help("Vista de cuadrícula")
                Image(systemName: "list.bullet")
                    .tag(LibraryViewMode.list)
                    .help("Vista de lista")
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            
            // Menú de Ordenación
            Menu {
                Picker("Ordenar por", selection: $sortField) {
                    ForEach(SortField.allCases, id: \.self) { field in
                        Text(field.localizedName).tag(field)
                    }
                }
                Divider()
                Button(sortAscending ? "Orden ascendente (A-Z)" : "Orden descendente (Z-A)") {
                    sortAscending.toggle()
                }
            } label: {
                Image(systemName: sortAscending ? "arrow.up.arrow.down" : "arrow.down.arrow.up")
                    .font(.system(size: 13))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
            .help("Opciones de ordenación")
            
            Spacer()
            
            // Campo de búsqueda con respuesta rápida
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ArcadeTheme.textTertiary)
                    .font(.system(size: 12))
                TextField("Buscar por título o sistema...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ArcadeTheme.textTertiary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(width: 220)
            
            // Indicador discreto del estado de la biblioteca
            HStack(spacing: 6) {
                Circle()
                    .fill(mameVersion != nil ? ArcadeTheme.statusGood : ArcadeTheme.statusWarning)
                    .frame(width: 6, height: 6)
                Text("\(totalGames) juegos • MAME \(mameVersion ?? "No detectado")")
                    .font(.system(size: 11))
                    .foregroundColor(ArcadeTheme.textTertiary)
            }
            .padding(.horizontal, 4)
            
            // Acceso rápido a Ajustes
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .help("Ajustes de la aplicación")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ArcadeTheme.surfaceRaised)
    }
}
