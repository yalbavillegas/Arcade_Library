import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Ventana principal de Arcade Library con barra lateral, barra de herramientas y área de contenido
public struct MainView: View {
    @State private var allGames: [Game] = []
    @State private var settings: AppSettings = AppSettings.default
    @State private var selectedGame: Game? = nil
    @State private var sidebarSelection: SidebarSelection = .all
    
    // Controles de barra de herramientas
    @State private var searchText: String = ""
    @State private var viewMode: LibraryViewMode = .grid
    @State private var sortField: SortField = .title
    @State private var sortAscending: Bool = true
    
    // Estados de interfaz y modales
    @State private var showSettingsSheet = false
    @State private var showAboutSheet = false
    @State private var isDropTargeted = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importStatusText: String = ""
    @State private var alertMessage: String? = nil
    @State private var showAlert = false
    
    public init() {}
    
    // MARK: - Filtrado y Ordenación de Juegos
    
    private var displayedGames: [Game] {
        var result = allGames
        
        // 1. Filtro de barra lateral
        switch sidebarSelection {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            result = result.filter { $0.lastPlayed != nil }
        case .problems:
            result = result.filter { $0.status == .missingFiles || $0.status == .fileNotFound }
        case .manufacturer(let mfg):
            result = result.filter { $0.manufacturer == mfg }
        case .year(let year):
            result = result.filter { $0.year == year }
        case .settings, .about:
            break
        }
        
        // 2. Filtro de búsqueda local inmediata
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedQuery.isEmpty {
            result = result.filter { game in
                game.title.lowercased().contains(trimmedQuery) ||
                game.systemName.lowercased().contains(trimmedQuery) ||
                (game.manufacturer?.lowercased().contains(trimmedQuery) ?? false) ||
                (game.year?.contains(trimmedQuery) ?? false)
            }
        }
        
        // 3. Ordenación
        result.sort { a, b in
            let comparison: Bool
            switch sortField {
            case .title:
                comparison = a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            case .year:
                let yA = a.year ?? ""
                let yB = b.year ?? ""
                comparison = yA < yB
            case .manufacturer:
                let mA = a.manufacturer ?? ""
                let mB = b.manufacturer ?? ""
                comparison = mA.localizedCaseInsensitiveCompare(mB) == .orderedAscending
            case .addedAt:
                comparison = a.addedAt < b.addedAt
            case .lastPlayed:
                let lpA = a.lastPlayed ?? Date.distantPast
                let lpB = b.lastPlayed ?? Date.distantPast
                comparison = lpA < lpB
            case .playCount:
                comparison = a.playCount < b.playCount
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    // MARK: - Vista Principal
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $sidebarSelection,
                allGames: allGames,
                onOpenSettings: { showSettingsSheet = true },
                onOpenAbout: { showAboutSheet = true }
            )
        } detail: {
            ZStack {
                VStack(spacing: 0) {
                    ToolbarView(
                        searchText: $searchText,
                        viewMode: $viewMode,
                        sortField: $sortField,
                        sortAscending: $sortAscending,
                        totalGames: allGames.count,
                        mameVersion: settings.detectedMAMEVersion,
                        onAddGames: { selectFilesToAdd() },
                        onRescanLibrary: { rescanLibrary() },
                        onDownloadMissingCovers: { downloadMissingCoversBatch() },
                        onOpenSettings: { showSettingsSheet = true }
                    )
                    
                    Divider()
                        .background(ArcadeTheme.borderSubtle)
                    
                    if viewMode == .grid {
                        GameGridView(
                            games: displayedGames,
                            cardSize: CGFloat(settings.cardSize),
                            selectedGame: $selectedGame,
                            onPlayGame: { launchGame($0) },
                            onToggleFavorite: { toggleFavorite($0) }
                        )
                    } else {
                        GameListView(
                            games: displayedGames,
                            selectedGame: $selectedGame,
                            onPlayGame: { launchGame($0) },
                            onToggleFavorite: { toggleFavorite($0) },
                            onRemoveGame: { removeGame($0) }
                        )
                    }
                }
                .background(ArcadeTheme.backgroundDark)
                
                // Zona de arrastrar y soltar superpuesta
                ImportDropOverlay(isTargeted: isDropTargeted)
                
                // Modal de progreso de importación
                if isImporting {
                    ImportProgressModal(
                        progress: importProgress,
                        statusText: importStatusText,
                        onCancel: { isImporting = false }
                    )
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDroppedFiles(providers)
        }
        .sheet(item: $selectedGame) { game in
            GameDetailSheet(
                game: game,
                settings: settings,
                onClose: { selectedGame = nil },
                onPlayGame: { launchGame($0) },
                onToggleFavorite: { toggleFavorite($0) },
                onCoverUpdated: { updatedGame, newCover in
                    if let gameId = updatedGame.id {
                        DatabaseService.shared.updateCover(gameId: gameId, imagePath: newCover)
                        refreshLibrary()
                        if var cur = selectedGame {
                            cur.coverImagePath = newCover
                            selectedGame = cur
                        }
                    }
                },
                onStatusUpdated: { updatedGame, newStatus in
                    if let gameId = updatedGame.id {
                        DatabaseService.shared.updateStatus(gameId: gameId, status: newStatus)
                        refreshLibrary()
                        if var cur = selectedGame {
                            cur.status = newStatus
                            selectedGame = cur
                        }
                    }
                },
                onRemoveGame: { gameToRemove in
                    removeGame(gameToRemove)
                }
            )
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(
                settings: $settings,
                onClose: { showSettingsSheet = false },
                onSettingsSaved: { newSettings in
                    DatabaseService.shared.saveSettings(newSettings)
                    self.settings = newSettings
                    self.viewMode = newSettings.viewMode
                    self.sortField = newSettings.sortField
                    self.sortAscending = newSettings.sortAscending
                }
            )
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView(onClose: { showAboutSheet = false })
        }
        .alert("Aviso", isPresented: $showAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Lógica de Carga y Acciones
    
    private func loadInitialData() {
        self.settings = DatabaseService.shared.loadSettings()
        self.viewMode = settings.viewMode
        self.sortField = settings.sortField
        self.sortAscending = settings.sortAscending
        refreshLibrary()
        
        // Auto-detectar versión de MAME si aún no se tiene
        Task {
            if case .success(let ver) = await MAMEIntegrationService.shared.detectVersion(executablePath: settings.mameExecutablePath) {
                await MainActor.run {
                    self.settings.detectedMAMEVersion = ver
                    DatabaseService.shared.saveSettings(self.settings)
                }
            }
        }
    }
    
    private func refreshLibrary() {
        self.allGames = DatabaseService.shared.getAllGames()
    }
    
    private func launchGame(_ game: Game) {
        let result = MAMEIntegrationService.shared.launchGame(
            game: game,
            settings: settings
        ) { launchResult in
            DispatchQueue.main.async {
                self.refreshLibrary()
                if !launchResult.success {
                    self.alertMessage = "MAME finalizó con error (código \(launchResult.exitCode)):\n\(launchResult.errorMessage ?? "Error desconocido")"
                    self.showAlert = true
                }
            }
        }
        
        if case .failure(let error) = result {
            self.alertMessage = error.localizedDescription
            self.showAlert = true
        }
    }
    
    private func toggleFavorite(_ game: Game) {
        guard let id = game.id else { return }
        let newFav = !game.isFavorite
        DatabaseService.shared.setFavorite(gameId: id, isFavorite: newFav)
        refreshLibrary()
        if var sel = selectedGame, sel.id == id {
            sel.isFavorite = newFav
            selectedGame = sel
        }
    }
    
    private func removeGame(_ game: Game) {
        guard let id = game.id else { return }
        _ = DatabaseService.shared.removeGameFromLibrary(gameId: id)
        refreshLibrary()
    }
    
    private func rescanLibrary() {
        let (total, missing) = DiagnosticService.shared.rescanLibraryFiles()
        refreshLibrary()
        self.alertMessage = "Análisis completado: \(total) títulos comprobados.\n\(missing > 0 ? "\(missing) archivo(s) no encontrados en su ruta original." : "Todos los archivos registrados están disponibles.")"
        self.showAlert = true
    }
    
    private func selectFilesToAdd() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [
            UTType(filenameExtension: "zip") ?? .zip,
            UTType(filenameExtension: "7z") ?? .archive
        ]
        panel.title = "Seleccionar archivos ROM o carpetas"
        
        if panel.runModal() == .OK {
            processURLs(panel.urls)
        }
    }
    
    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        var droppedURLs: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    droppedURLs.append(url)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !droppedURLs.isEmpty {
                self.processURLs(droppedURLs)
            }
        }
        return true
    }
    
    private func processURLs(_ urls: [URL]) {
        self.isImporting = true
        self.importProgress = 0.0
        self.importStatusText = "Iniciando análisis..."
        
        Task {
            let res = await ImportService.shared.importURLs(urls, settings: settings) { progress, status in
                Task { @MainActor in
                    self.importProgress = progress
                    self.importStatusText = status
                }
            }
            
            await MainActor.run {
                self.isImporting = false
                self.refreshLibrary()
                
                var msg = "Incorporados: \(res.importedGames.count) juego(s)."
                if res.duplicateCount > 0 {
                    msg += "\nOmitidos por duplicado: \(res.duplicateCount)."
                }
                if res.invalidFilesCount > 0 {
                    msg += "\nArchivos no válidos: \(res.invalidFilesCount)."
                }
                if !res.errorMessages.isEmpty {
                    msg += "\nErrores: \(res.errorMessages.joined(separator: ", "))"
                }
                self.alertMessage = msg
                self.showAlert = true
            }
        }
    }
    
    private func downloadMissingCoversBatch() {
        let missingCount = allGames.filter { $0.coverImagePath == nil || !FileManager.default.fileExists(atPath: $0.coverImagePath!) }.count
        guard missingCount > 0 else {
            self.alertMessage = "Todos los juegos de tu biblioteca ya tienen carátula asignada."
            self.showAlert = true
            return
        }
        
        self.isImporting = true
        self.importProgress = 0.0
        self.importStatusText = "Buscando carátulas en línea..."
        
        let artworkType = OnlineArtworkType(rawValue: settings.preferredArtworkType) ?? .flyer
        
        Task {
            let (downloaded, failed) = await ArtworkService.shared.downloadBatchMissingArtwork(
                games: allGames,
                type: artworkType
            ) { progress, status in
                Task { @MainActor in
                    self.importProgress = progress
                    self.importStatusText = status
                }
            }
            
            await MainActor.run {
                self.isImporting = false
                self.refreshLibrary()
                self.alertMessage = "Descarga en línea completada:\n• \(downloaded) carátula(s) obtenidas con éxito.\n" + (failed > 0 ? "• \(failed) no encontradas en repositorios públicos." : "")
                self.showAlert = true
            }
        }
    }
}
