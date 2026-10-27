import SwiftUI
import AppKit

/// Vista completa de configuración de Arcade Library
public struct SettingsView: View {
    @Binding public var settings: AppSettings
    public let onClose: () -> Void
    public let onSettingsSaved: (AppSettings) -> Void
    
    @State private var selectedTab = 0
    @State private var currentSettings: AppSettings
    @State private var diagnosticReport: DiagnosticReport? = nil
    @State private var isTestingMame = false
    @State private var mameTestMessage: String? = nil
    @State private var dataStatusMessage: String? = nil
    
    public init(
        settings: Binding<AppSettings>,
        onClose: @escaping () -> Void,
        onSettingsSaved: @escaping (AppSettings) -> Void
    ) {
        self._settings = settings
        self.onClose = onClose
        self.onSettingsSaved = onSettingsSaved
        self._currentSettings = State(initialValue: settings.wrappedValue)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera
            HStack {
                Text("Ajustes de Arcade Library")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ArcadeTheme.textPrimary)
                Spacer()
                Button("Cerrar") {
                    saveAndClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(18)
            .background(ArcadeTheme.surfaceRaised)
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            // Selector de pestañas
            Picker("", selection: $selectedTab) {
                Text("MAME").tag(0)
                Text("Biblioteca").tag(1)
                Text("Apariencia").tag(2)
                Text("Datos").tag(3)
                Text("Diagnóstico").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            
            // Contenido de la pestaña
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case 0: mameTab
                    case 1: libraryTab
                    case 2: appearanceTab
                    case 3: dataTab
                    case 4: diagnosticTab
                    default: EmptyView()
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .background(ArcadeTheme.backgroundDark)
        .onAppear {
            loadDiagnostics()
        }
    }
    
    // MARK: - Pestaña MAME
    
    private var mameTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("INTEGRACIÓN CON EL EJECUTABLE DE MAME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ruta del ejecutable:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ArcadeTheme.textPrimary)
                
                HStack {
                    TextField("Ruta del ejecutable", text: $currentSettings.mameExecutablePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    
                    Button("Examinar...") {
                        selectMAMEExecutable()
                    }
                    
                    Button(isTestingMame ? "Verificando..." : "Detectar") {
                        testMAMEBinary()
                    }
                    .disabled(isTestingMame)
                }
                
                if let msg = mameTestMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(currentSettings.detectedMAMEVersion != nil ? ArcadeTheme.statusGood : ArcadeTheme.statusBad)
                }
            }
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            Text("OPCIONES DE LANZAMIENTO")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            Toggle("Ejecutar en modo ventana (-window)", isOn: $currentSettings.launchWindowed)
                .toggleStyle(.checkbox)
            
            Toggle("Omitir pantalla de información del juego al iniciar (-skip_gameinfo)", isOn: $currentSettings.skipGameInfo)
                .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Argumentos adicionales permitidos:")
                    .font(.system(size: 13, weight: .medium))
                TextField("ej: -video opengl -sound coreaudio", text: $currentSettings.additionalArguments)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                Text("Solo se aceptan parámetros que comiencen con '-'. No se permite concatenación de comandos de shell.")
                    .font(.system(size: 11))
                    .foregroundColor(ArcadeTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Pestaña Biblioteca
    
    private var libraryTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("DIRECTORIOS DE ROMS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(currentSettings.romDirectories, id: \.self) { dir in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(ArcadeTheme.accent)
                        Text(dir)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            currentSettings.romDirectories.removeAll { $0 == dir }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(ArcadeTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button("Añadir carpeta de ROMs...") {
                    addDirectory(to: &currentSettings.romDirectories)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            Text("DIRECTORIOS DE CARÁTULAS E IMÁGENES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(currentSettings.imageDirectories, id: \.self) { dir in
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(ArcadeTheme.accent)
                        Text(dir)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            currentSettings.imageDirectories.removeAll { $0 == dir }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(ArcadeTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button("Añadir carpeta de imágenes...") {
                    addDirectory(to: &currentSettings.imageDirectories)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            Text("PREFERENCIAS DE IMPORTACIÓN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            Toggle("Prevenir duplicados (ignorar archivos con el mismo identificador)", isOn: $currentSettings.preventDuplicates)
                .toggleStyle(.checkbox)
            
            Toggle("Verificar integridad técnica con MAME al importar", isOn: $currentSettings.autoVerifyOnImport)
                .toggleStyle(.checkbox)
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            Text("CARÁTULAS EN LÍNEA")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            Toggle("Descargar carátula en línea automáticamente al importar si no existe localmente", isOn: $currentSettings.autoDownloadArtworkOnImport)
                .toggleStyle(.checkbox)
            
            Picker("Tipo de imagen preferido:", selection: $currentSettings.preferredArtworkType) {
                Text("Flyer / Carátula publicitaria").tag("flyer")
                Text("Captura de pantalla (Snap)").tag("snap")
                Text("Pantalla de título (Title)").tag("title")
            }
            .pickerStyle(.radioGroup)
            
            Text("Fuentes públicas y abiertas: Arcade Database (ArcadeItalia ADB) y Libretro Thumbnails. No requiere cuenta comercial ni suscripciones.")
                .font(.system(size: 11))
                .foregroundColor(ArcadeTheme.textTertiary)
        }
    }
    
    // MARK: - Pestaña Apariencia
    
    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("TEMA Y PRESENTACIÓN VISUAL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            Toggle("Tema oscuro (Estilo grafito y negro)", isOn: $currentSettings.isDarkTheme)
                .toggleStyle(.checkbox)
            
            Picker("Vista predeterminada:", selection: $currentSettings.viewMode) {
                Text("Cuadrícula").tag(LibraryViewMode.grid)
                Text("Lista").tag(LibraryViewMode.list)
            }
            .pickerStyle(.radioGroup)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Tamaño de tarjetas en cuadrícula:")
                    Spacer()
                    Text("\(Int(currentSettings.cardSize)) px")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ArcadeTheme.textSecondary)
                }
                Slider(value: $currentSettings.cardSize, in: 140...260, step: 10)
            }
        }
    }
    
    // MARK: - Pestaña Datos
    
    private var dataTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("BASE DE DATOS LOCAL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ubicación del archivo SQLite:")
                    .font(.system(size: 12, weight: .medium))
                Text(DatabaseService.shared.databasePath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ArcadeTheme.textSecondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Divider()
                .background(ArcadeTheme.borderSubtle)
            
            Text("COPIA DE SEGURIDAD Y RESTAURACIÓN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            HStack(spacing: 14) {
                Button("Exportar copia de seguridad...") {
                    exportBackup()
                }
                .buttonStyle(.bordered)
                
                Button("Restaurar desde copia...") {
                    restoreBackup()
                }
                .buttonStyle(.bordered)
            }
            
            if let msg = dataStatusMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(ArcadeTheme.accent)
            }
        }
    }
    
    // MARK: - Pestaña Diagnóstico
    
    private var diagnosticTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("DIAGNÓSTICO DEL SISTEMA Y RUTAS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ArcadeTheme.textTertiary)
            
            if let report = diagnosticReport {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Versión de la app:")
                            .foregroundColor(ArcadeTheme.textTertiary)
                        Text(report.appVersion)
                    }
                    GridRow {
                        Text("Arquitectura:")
                            .foregroundColor(ArcadeTheme.textTertiary)
                        Text(report.architecture)
                    }
                    GridRow {
                        Text("Sistema Operativo:")
                            .foregroundColor(ArcadeTheme.textTertiary)
                        Text(report.osVersion)
                    }
                    GridRow {
                        Text("Estado MAME:")
                            .foregroundColor(ArcadeTheme.textTertiary)
                        HStack {
                            Circle()
                                .fill(report.isMameValid ? ArcadeTheme.statusGood : ArcadeTheme.statusBad)
                                .frame(width: 8, height: 8)
                            Text(report.isMameValid ? "Detectado (v\(report.mameVersion ?? "—"))" : "Ruta no válida")
                        }
                    }
                    GridRow {
                        Text("Juegos en biblioteca:")
                            .foregroundColor(ArcadeTheme.textTertiary)
                        Text("\(report.totalGamesInLibrary) (\(report.verifiedGamesCount) verificados)")
                    }
                }
                .font(.system(size: 13))
            } else {
                ProgressView("Cargando diagnóstico...")
            }
            
            Button("Actualizar diagnóstico") {
                loadDiagnostics()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    // MARK: - Métodos de Apoyo
    
    private func saveAndClose() {
        settings = currentSettings
        onSettingsSaved(currentSettings)
        onClose()
    }
    
    private func selectMAMEExecutable() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Seleccionar ejecutable de MAME"
        if panel.runModal() == .OK, let url = panel.url {
            currentSettings.mameExecutablePath = url.path
            testMAMEBinary()
        }
    }
    
    private func testMAMEBinary() {
        isTestingMame = true
        mameTestMessage = nil
        Task {
            let res = await MAMEIntegrationService.shared.detectVersion(executablePath: currentSettings.mameExecutablePath)
            await MainActor.run {
                self.isTestingMame = false
                switch res {
                case .success(let ver):
                    self.currentSettings.detectedMAMEVersion = ver
                    self.mameTestMessage = "MAME detectado con éxito: versión \(ver)"
                case .failure(let err):
                    self.currentSettings.detectedMAMEVersion = nil
                    self.mameTestMessage = "Error al detectar MAME: \(err.localizedDescription)"
                }
            }
        }
    }
    
    private func addDirectory(to array: inout [String]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Seleccionar directorio"
        if panel.runModal() == .OK, let url = panel.url {
            if !array.contains(url.path) {
                array.append(url.path)
            }
        }
    }
    
    private func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Guardar copia de seguridad de Arcade Library"
        panel.nameFieldStringValue = "ArcadeLibrary_Backup_\(Date().formatted(.iso8601.year().month().day())).json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try DatabaseService.shared.exportBackup(to: url)
                dataStatusMessage = "Copia exportada con éxito en: \(url.lastPathComponent)"
            } catch {
                dataStatusMessage = "Error al exportar: \(error.localizedDescription)"
            }
        }
    }
    
    private func restoreBackup() {
        let panel = NSOpenPanel()
        panel.title = "Seleccionar archivo de copia de seguridad (.json)"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let count = try DatabaseService.shared.restoreBackup(from: url)
                currentSettings = DatabaseService.shared.loadSettings()
                dataStatusMessage = "Restauración completada: \(count) juegos recuperados."
            } catch {
                dataStatusMessage = "Error al restaurar: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadDiagnostics() {
        Task {
            let rep = await DiagnosticService.shared.generateReport(settings: currentSettings)
            await MainActor.run {
                self.diagnosticReport = rep
            }
        }
    }
}
