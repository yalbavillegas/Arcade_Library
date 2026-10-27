# Arcade Library

**Frontend moderno para MAME en macOS (Apple Silicon ARM64)**

Arcade Library es una aplicación de escritorio nativa para macOS diseñada para administrar, explorar y ejecutar juegos arcade mediante una biblioteca visual moderna y elegante, integrándose directamente con una instalación existente de MAME sin necesidad de utilizar la Terminal para las operaciones habituales.

---

## Créditos y Autoría

* **Ingeniería de software y desarrollo:** Yessid Alba
* **Diseño de interfaz y experiencia de usuario:** Yessid Alba
* **Arquitectura e integración con MAME:** Yessid Alba
* **Dirección técnica del proyecto:** Yessid Alba

---

## Características Principales

* **Experiencia 100% Nativa en Apple Silicon:** Desarrollada con Swift 6 y SwiftUI, optimizada para procesadores M1/M2/M3/M4 (ARM64) con mínimo consumo de memoria RAM (~30 MB frente a los 400+ MB de soluciones basadas en navegadores).
* **Diseño Minimalista y Refinado:** Interfaz con tema oscuro en tonos grafito y negro, superficies discretas, tipografía moderna, compatibilidad con pantallas Retina y sutiles animaciones.
* **Integración Real con MAME:**
  * Detección automática de la instalación y versión existente de MAME (ej: `/opt/homebrew/bin/mame`).
  * Consulta técnica mediante `mame -listxml` y `mame -listfull`.
  * Verificación de la integridad de los conjuntos de ROM mediante `mame -verifyroms`.
  * Ejecución segura y asíncrona mediante APIs de proceso (`Foundation.Process`) sin pasar por shell ni concatenación vulnerable de cadenas.
  * Capacidad de minimizar o cerrar la ventana de la biblioteca mientras MAME continúa ejecutándose.
  * Prevención activa de múltiples instancias simultáneas del mismo juego.
* **Importación Rápida y No Destructiva:**
  * Arrastrar y soltar (Drag and Drop) directo desde Finder de archivos `.zip`, `.7z` o carpetas completas.
  * Selector nativo de archivos con `NSOpenPanel`.
  * Identificación automática del título comercial, fabricante, año, orientación de pantalla, jugadores y dependencias.
  * Los archivos ROM originales nunca se mueven, renombran ni eliminan.
* **Gestión de Carátulas e Ilustraciones:**
  * Resolución por orden de prioridad: carátula asignada por el usuario > carpetas de imágenes configuradas (`<sistema>.png`) > tarjeta de reserva elegante con emblema arcade.
  * Permite asignar o cambiar manualmente la carátula de cualquier juego.
* **Persistencia Robusta en SQLite:**
  * Motor relacional nativo `libsqlite3` de macOS.
  * Índices rápidos para búsqueda instantánea en milisegundos incluso con miles de títulos.
  * Registro de favoritos, partidas jugadas, tiempo total de juego y fecha del último lanzamiento.
  * Copia de seguridad exportable a archivo JSON estándar y restauración completa.
* **Ficha Técnica Detallada:**
  * Muestra estado del ROM (Verificado, Incompleto, No encontrado, Sin verificar).
  * Relaciones de clon y juego original (parent/clone, `romof`, `cloneof`, `sampleof`).
  * Detección de necesidad de imágenes de disco duro virtual CHD.
  * Botón para mostrar el archivo ROM directamente en Finder (`NSWorkspace`).
  * Opción para retirar el juego de la biblioteca (con confirmación explícita de que el archivo físico se mantiene intacto).

---

## Requisitos del Sistema

* **Sistema Operativo:** macOS 14.0 (Sonoma) o superior (probado en macOS Tahoe / versión 26.5.2).
* **Arquitectura:** Apple Silicon (ARM64).
* **MAME:** Instalación local existente de MAME (ej: instalada vía Homebrew en `/opt/homebrew/bin/mame` o binario personalizado).

---

## Estructura del Proyecto

```
Arcade_Library/
├── App/
│   ├── AppDelegate.swift           # Configuración de apariencia y ciclo de vida de la ventana
│   └── ArcadeLibraryApp.swift      # Punto de entrada principal (@main) de la aplicación
├── Models/
│   ├── Game.swift                  # Modelo de datos del juego y estados de verificación
│   ├── AppSettings.swift           # Preferencias globales, ordenación y vistas
│   └── MAMESystemInfo.swift        # Datos extraídos del XML de MAME y registro de ejecuciones
├── Services/
│   ├── DatabaseService.swift       # Capa de persistencia relacional con SQLite3 nativo
│   ├── MAMEIntegrationService.swift # Detección, validación, parser XML y ejecución de MAME
│   ├── ImportService.swift         # Análisis, validación e importación de archivos ROM
│   ├── ArtworkService.swift        # Resolución local y asignación de carátulas
│   └── DiagnosticService.swift     # Diagnóstico del entorno y reanálisis de archivos
├── Theme/
│   └── ArcadeTheme.swift           # Sistema de diseño, paleta de colores grafito y radios
├── Views/
│   ├── MainView.swift              # Coordinador de interfaz, split view y drag-and-drop
│   ├── SidebarView.swift           # Barra lateral con categorías reales y filtros dinámicos
│   ├── ToolbarView.swift           # Barra superior con búsqueda instantánea y controles
│   ├── GameGridView.swift          # Vista de cuadrícula responsiva con tarjetas visuales
│   ├── GameListView.swift          # Vista de lista detallada con columnas y ordenación
│   ├── GameCardView.swift          # Tarjeta visual con badges de estado y carátula
│   ├── GameDetailSheet.swift       # Ficha técnica completa del juego y botón Jugar
│   ├── SettingsView.swift          # Panel de configuración categorizado
│   ├── AboutView.swift             # Vista de créditos con autoría de Yessid Alba
│   └── ImportDropZoneView.swift    # Indicador visual para arrastrar y soltar
├── Resources/
│   └── Info.plist                  # Metadatos del paquete de aplicación para macOS
├── Tests/
│   └── ArcadeLibraryTests.swift    # Suite con las 15 pruebas automatizadas de validación
└── scripts/
    ├── build_app.sh                # Script para compilar y generar Arcade Library.app
    └── run_tests.sh                # Script para ejecutar la suite de pruebas automatizadas
```

---

## Compilación y Generación del Ejecutable

Para compilar la aplicación y empaquetarla en el bundle estándar de macOS `build/Arcade Library.app`:

```bash
./scripts/build_app.sh
```

El script compilará todos los módulos en código máquina nativo ARM64 con optimización `-O` y configurará la estructura interna del bundle:

* `build/Arcade Library.app/Contents/MacOS/ArcadeLibrary`
* `build/Arcade Library.app/Contents/Info.plist`

Para ejecutar la aplicación compilada:

```bash
open "build/Arcade Library.app"
```

---

## Suite de Pruebas Automatizadas

El proyecto incluye 15 pruebas automatizadas que verifican todas las funciones críticas requeridas:

1. **Apertura de la aplicación sin ruta de MAME configurada:** Rechazo controlado y validación sin excepciones.
2. **Configuración de un ejecutable válido:** Comprobación del binario `/opt/homebrew/bin/mame`.
3. **Detección de una versión de MAME:** Consulta asíncrona de `mame -version` (detectado v0.289).
4. **Importación de un archivo:** Análisis y almacenamiento en base de datos.
5. **Rechazo controlado de entradas no válidas:** Rechazo de caracteres no permitidos e inyección.
6. **Detección de duplicados:** Identificación de ROMs previamente existentes.
7. **Persistencia de la biblioteca:** Guardado y recuperación completa desde SQLite.
8. **Búsqueda y filtrado:** Filtrado local por nombre, fabricante y año.
9. **Guardado de favoritos:** Marcado y persistencia del estado favorito.
10. **Asignación de carátulas:** Resolución y asociación de imágenes personalizadas.
11. **Manejo de rutas inexistentes:** Detección de archivos movidos o eliminados y marcado como `fileNotFound`.
12. **Lanzamiento controlado de un juego:** Ejecución segura con parámetros controlados.
13. **Manejo de errores del proceso de MAME:** Captura de códigos de retorno de error (código 2) y mensajes en stderr.
14. **Copia de seguridad y restauración de los datos:** Exportación completa a JSON y posterior recuperación.
15. **Retirada de un título sin borrar el ROM original:** Borrado del registro en base de datos conservando intacto el archivo físico en disco.

Para ejecutar las 15 pruebas automatizadas:

```bash
./scripts/run_tests.sh
```

**Resultado de la validación:** 15 de 15 pruebas superadas con éxito (15/15 PASS).

---

## Instrucciones de Configuración de MAME

1. Abre **Arcade Library**.
2. Pulsa en el icono de **Ajustes** (o en la barra lateral selecciona *Ajustes*).
3. En la pestaña **MAME**, verifica que la ruta apunte a tu ejecutable (por defecto `/opt/homebrew/bin/mame`).
4. Haz clic en **Detectar** para confirmar que la versión de MAME es reconocida.
5. Puedes activar la opción *Ejecutar en modo ventana (-window)* si deseas jugar sin ocupar toda la pantalla, u omitir pantallas informativas iniciales con `-skip_gameinfo`.

---

## Instrucciones para Importar Juegos

Existen dos métodos rápidos para incorporar juegos a tu colección:

### Método 1: Arrastrar y Soltar (Recomendado)
1. Abre Finder y navega hasta la carpeta donde tengas tus archivos ROM (`.zip` o `.7z`).
2. Selecciona uno o varios archivos (o carpetas con ROMs) y arrástralos sobre la ventana de **Arcade Library**.
3. Aparecerá una zona visual indicando *Suelta los archivos ROM aquí*.
4. Al soltarlos, la aplicación analizará el nombre de cada archivo, consultará los metadatos en MAME e incorporará los títulos a la biblioteca.

### Método 2: Selector de Archivos
1. En la barra superior, haz clic en el botón **+ Agregar juegos**.
2. Selecciona los archivos o carpetas que deseas incorporar y pulsa *Abrir*.

*Nota importante:* La importación crea un enlace lógico en la base de datos manteniendo la ruta original de los archivos ROM. No se copian ni modifican tus archivos existentes.

---

## Instrucciones para Generar una Distribución (DMG)

Para generar una imagen de disco distribuible `.dmg` lista para compartir:

```bash
hdiutil create -volname "Arcade Library" -srcfolder "build/Arcade Library.app" -ov -format UDZO "build/Arcade_Library_1.0.0_arm64.dmg"
```

---

## Tecnologías y Dependencias de Terceros

* **Swift 6 & SwiftUI:** Interfaz de usuario declarativa nativa de macOS.
* **AppKit & UniformTypeIdentifiers:** Integración con el sistema de ventanas, arrastrar y soltar y diálogos de archivo nativos.
* **SQLite3 (libsqlite3.dylib):** Motor de base de datos relacional nativo provisto por el sistema operativo macOS (sin dependencias externas).
* **MAME CLI:** Emulador instalado por el usuario en macOS, ejecutado mediante su interfaz oficial de línea de comandos.

---

## Licencia

Copyright © 2026 Yessid Alba. Todos los derechos reservados.
Distribuido bajo los términos de la Licencia MIT.
