import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
}

enum L10nKey {
    case settingsTitle
    case settingsSubtitle
    case githubUsername
    case usernamePlaceholder
    case usernameStoredHint
    case githubToken
    case tokenStored
    case tokenNotSaved
    case tokenStoredHint
    case saveToken
    case deleteToken
    case tokenSavedMessage
    case tokenDeletedMessage
    case appTitle
    case appSubtitle
    case githubUser
    case notSet
    case tokenLabel
    case tokenOptional
    case tokenStoredInKeychain
    case repositories
    case withDownloads
    case totalDownloads
    case runReport
    case running
    case cancel
    case copyOutput
    case clear
    case settings
    case language
    case liveOutput
    case selectableAutoScrolls
    case outputEmpty
    case runStateReady
    case runStateRunning
    case runStateCompleted
    case runStateFailed
    case runStateCancelled
    case languageSelectorTitle
    case languageSelectorSubtitle
    case appLanguage
    case selectedLanguage
    case languageApplyHint
    case languageChangeConfirmationTitle
    case languageChangeConfirmationMessage
    case apply
    case keepCurrentLanguage
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let username = "githubUsername"
        static let language = "appLanguage"
    }

    @Published var githubUsername: String {
        didSet {
            UserDefaults.standard.set(githubUsername, forKey: Keys.username)
        }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published private(set) var hasStoredToken: Bool

    private let keychain = KeychainTokenStore()

    init() {
        githubUsername = UserDefaults.standard.string(forKey: Keys.username) ?? ""
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.language) ?? "") ?? .english
        hasStoredToken = keychain.hasToken()
    }

    func trimmedUsername() -> String {
        githubUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadToken() -> String? {
        try? keychain.readToken()
    }

    func saveToken(_ token: String) throws {
        try keychain.saveToken(token)
        hasStoredToken = true
    }

    func deleteToken() throws {
        try keychain.deleteToken()
        hasStoredToken = false
    }

    func text(_ key: L10nKey) -> String {
        language.text(key)
    }
}

private extension AppLanguage {
    func text(_ key: L10nKey) -> String {
        switch self {
        case .english:
            switch key {
            case .settingsTitle: return "Settings"
            case .settingsSubtitle: return "Save the last GitHub username in \"UserDefaults\". Save the classic token only in the macOS Keychain."
            case .githubUsername: return "GitHub username"
            case .usernamePlaceholder: return "perez987"
            case .usernameStoredHint: return "This value is stored locally for the user's convenience."
            case .githubToken: return "GitHub classic token"
            case .tokenStored: return "Stored in Keychain"
            case .tokenNotSaved: return "Not saved"
            case .tokenStoredHint: return "Stored with service name \"github-release-downloads\" for the current macOS account, always securely (never plain text)."
            case .saveToken: return "Save Token"
            case .deleteToken: return "Delete Token"
            case .tokenSavedMessage: return "Token saved securely in the keychain."
            case .tokenDeletedMessage: return "Token removed from the keychain."
            case .appTitle: return "GitHub Total Downloads"
            case .appSubtitle: return "macOS dashboard that displays the total number of downloads from all repositories."
            case .githubUser: return "GitHub user"
            case .notSet: return "Not set"
            case .tokenLabel: return "Token"
            case .tokenOptional: return "Optional"
            case .tokenStoredInKeychain: return "Stored in Keychain"
            case .repositories: return "Repositories"
            case .withDownloads: return "With Downloads"
            case .totalDownloads: return "Total Downloads"
            case .runReport: return "Run"
            case .running: return "Running…"
            case .cancel: return "Cancel"
            case .copyOutput: return "Copy"
            case .clear: return "Clear"
            case .settings: return "Settings"
            case .language: return "Language"
            case .liveOutput: return "Live output"
            case .selectableAutoScrolls: return "Selectable • Auto-scrolls"
            case .outputEmpty: return "Downloads by repository and the grand total will be displayed here."
            case .runStateReady: return "Ready"
            case .runStateRunning: return "Running"
            case .runStateCompleted: return "Completed"
            case .runStateFailed: return "Failed"
            case .runStateCancelled: return "Cancelled"
            case .languageSelectorTitle: return "Language"
            case .languageSelectorSubtitle: return "Choose the app language. The app applies the new language after you confirm the change."
            case .appLanguage: return "App language"
            case .selectedLanguage: return "Selected language"
            case .languageApplyHint: return "The selected language is used in all windows."
            case .languageChangeConfirmationTitle: return "Switch language?"
            case .languageChangeConfirmationMessage: return "The app will switch to %@ after you confirm."
            case .apply: return "Apply"
            case .keepCurrentLanguage: return "Keep current language"
            }
        case .spanish:
            switch key {
            case .settingsTitle: return "Configuración"
            case .settingsSubtitle: return "Guarda el último usuario de GitHub en \"UserDefaults\". Guarda el token clásico en el llavero de macOS."
            case .githubUsername: return "Usuario de GitHub"
            case .usernamePlaceholder: return "perez987"
            case .usernameStoredHint: return "Este valor se guarda localmente para comodidad del usuario."
            case .githubToken: return "Token clásico de GitHub"
            case .tokenStored: return "Guardado en el llavero"
            case .tokenNotSaved: return "No guardado"
            case .tokenStoredHint: return "Se guarda con el nombre de servicio \"github-release-downloads\" para la cuenta actual de macOS, siempre de forma segura (nunca texto plano)."
            case .saveToken: return "Guardar token"
            case .deleteToken: return "Eliminar token"
            case .tokenSavedMessage: return "Token guardado de forma segura en el llavero."
            case .tokenDeletedMessage: return "Token eliminado del llavero."
            case .appTitle: return "Descargas Totales de GitHub"
            case .appSubtitle: return "Aplicación de macOS que muestra el número total de descargas de todos los repositorios."
            case .githubUser: return "Usuario de GitHub"
            case .notSet: return "Sin definir"
            case .tokenLabel: return "Token"
            case .tokenOptional: return "Opcional"
            case .tokenStoredInKeychain: return "Guardado en el llavero"
            case .repositories: return "Repositorios"
            case .withDownloads: return "Con descargas"
            case .totalDownloads: return "Descargas totales"
            case .runReport: return "Ejecutar"
            case .running: return "Ejecutando…"
            case .cancel: return "Cancelar"
            case .copyOutput: return "Copiar"
            case .clear: return "Limpiar"
            case .settings: return "Configuración"
            case .language: return "Idioma"
            case .liveOutput: return "Salida en vivo"
            case .selectableAutoScrolls: return "Seleccionable • Auto desplazamiento"
            case .outputEmpty: return "Aquí se mostrarán las descargas por repositorio y la suma total."
            case .runStateReady: return "Listo"
            case .runStateRunning: return "Ejecutando"
            case .runStateCompleted: return "Completado"
            case .runStateFailed: return "Falló"
            case .runStateCancelled: return "Cancelado"
            case .languageSelectorTitle: return "Idioma"
            case .languageSelectorSubtitle: return "Elige el idioma de la app. La app aplicará el nuevo idioma después de que confirmes el cambio."
            case .appLanguage: return "Idioma de la app"
            case .selectedLanguage: return "Idioma seleccionado"
            case .languageApplyHint: return "El idioma seleccionado se usa en todas las ventanas."
            case .languageChangeConfirmationTitle: return "¿Cambiar idioma?"
            case .languageChangeConfirmationMessage: return "La app cambiará a %@ después de confirmar."
            case .apply: return "Aplicar"
            case .keepCurrentLanguage: return "Mantener idioma actual"
            }
        }
    }
}
