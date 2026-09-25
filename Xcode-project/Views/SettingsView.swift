import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var tokenInput = ""
    @State private var saveMessage = ""
    @State private var saveMessageIsSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.26),
                    Color(red: 0.14, green: 0.24, blue: 0.34),
                    Color(red: 0.20, green: 0.18, blue: 0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(settings.text(.settingsTitle))
                        .font(.largeTitle.weight(.bold))

                    Text(settings.text(.settingsSubtitle))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                glassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(settings.text(.githubUsername), systemImage: "person.crop.circle.fill")
                            .font(.headline)

                        TextField(settings.text(.usernamePlaceholder), text: $settings.githubUsername)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text(settings.text(.usernameStoredHint))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                glassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label(settings.text(.githubToken), systemImage: "key.fill")
                                .font(.headline)
                            Spacer()
                            Text(settings.hasStoredToken ? settings.text(.tokenStored) : settings.text(.tokenNotSaved))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(settings.hasStoredToken ? .green : .secondary)
                        }

                        SecureField("ghp_…", text: $tokenInput)
                            .textContentType(.none)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text(settings.text(.tokenStoredHint))
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button(settings.text(.saveToken)) {
                                do {
                                    try settings.saveToken(tokenInput)
                                    tokenInput = ""
                                    saveMessage = settings.text(.tokenSavedMessage)
                                    saveMessageIsSuccess = true
                                } catch {
                                    saveMessage = error.localizedDescription
                                    saveMessageIsSuccess = false
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Button(settings.text(.deleteToken)) {
                                do {
                                    try settings.deleteToken()
                                    tokenInput = ""
                                    saveMessage = settings.text(.tokenDeletedMessage)
                                    saveMessageIsSuccess = true
                                } catch {
                                    saveMessage = error.localizedDescription
                                    saveMessageIsSuccess = false
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                LanguageSelectorButton(minWidth: 120)

                if saveMessage.isEmpty == false {
                    Label {
                        Text(saveMessage)
                            .font(.footnote.weight(.medium))
                    } icon: {
                        Image(systemName: saveMessageIsSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(saveMessageIsSuccess ? .green : .red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}

struct LanguageSelectorButton: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var settings: SettingsStore

    let minWidth: CGFloat

    var body: some View {
        Button {
            openWindow(id: "language-selector")
        } label: {
            Label(settings.text(.language), systemImage: "globe")
                .frame(minWidth: minWidth)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct LanguageSelectorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var selectedLanguage: AppLanguage = .english
    @State private var pendingLanguage: AppLanguage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.26),
                    Color(red: 0.14, green: 0.24, blue: 0.34),
                    Color(red: 0.20, green: 0.18, blue: 0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(settings.text(.languageSelectorTitle))
                        .font(.largeTitle.weight(.bold))
                    Text(settings.text(.languageSelectorSubtitle))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                glassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(settings.text(.appLanguage), systemImage: "globe")
                            .font(.headline)

                        Picker(settings.text(.selectedLanguage), selection: $selectedLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName)
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Text(settings.text(.languageApplyHint))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .onAppear {
            selectedLanguage = settings.language
        }
        .onChange(of: selectedLanguage) { oldValue, newValue in
            guard newValue != settings.language else {
                return
            }
            guard pendingLanguage == nil else {
                selectedLanguage = oldValue
                return
            }
            pendingLanguage = newValue
        }
        .alert(settings.text(.languageChangeConfirmationTitle), isPresented: isConfirmationPresented) {
            Button(settings.text(.keepCurrentLanguage), role: .cancel) {
                pendingLanguage = nil
                selectedLanguage = settings.language
            }
            Button(settings.text(.apply)) {
                if let pendingLanguage {
                    settings.language = pendingLanguage
                    selectedLanguage = pendingLanguage
                    self.pendingLanguage = nil
                }
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationMessage: String {
        String(format: settings.text(.languageChangeConfirmationMessage), pendingLanguage?.displayName ?? selectedLanguage.displayName)
    }

    private var isConfirmationPresented: Binding<Bool> {
        Binding {
            pendingLanguage != nil
        } set: { shouldShow in
            if shouldShow == false {
                pendingLanguage = nil
                selectedLanguage = settings.language
            }
        }
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}
