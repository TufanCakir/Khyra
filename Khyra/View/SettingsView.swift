//
//  SettingsView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

#if canImport(FoundationModels)
    import FoundationModels
#endif

struct SettingsView: View {
    let model: EditorModel

    @Environment(\.openURL) private var openURL

    private let appStoreReviewURL = URL(
        string:
            "itms-apps://itunes.apple.com/app/id6757344224?action=write-review"
    )

    private var strings: AppStrings {
        model.appStrings
    }

    private var theme: EditorTheme {
        model.selectedTheme
    }

    private var themeSelection: Binding<String> {
        Binding(
            get: { model.selectedThemeID },
            set: { model.selectedThemeID = $0 }
        )
    }

    private var languageSelection: Binding<String> {
        Binding(
            get: { model.appLanguageCode },
            set: { model.setLanguage($0) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                appearanceSection
                languageSection
                AISettingsSection(model: model)
                aboutSection
                supportSection
                appInfoSection
            }
            .padding()
        }
        .background {
            theme.background
                .ignoresSafeArea()
        }
        .foregroundStyle(theme.primaryText)
        .tint(theme.accent)
        .navigationTitle(strings.settings)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(theme.preferredScheme)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        settingsSection(strings.appearance) {
            Picker(selection: themeSelection) {
                ForEach(EditorTheme.all) { item in
                    Text(item.name)
                        .tag(item.id)
                }
            } label: {
                SettingsRow(
                    title: strings.theme,
                    subtitle: theme.name,
                    theme: theme
                )
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        settingsSection(strings.language) {
            Picker(selection: languageSelection) {
                Text("System")
                    .tag("system")

                Text(strings.german)
                    .tag("de")

                Text(strings.english)
                    .tag("en")
            } label: {
                SettingsRow(
                    title: strings.language,
                    subtitle: selectedLanguageName,
                    theme: theme
                )
            }
            .pickerStyle(.menu)
        }
    }

    private var selectedLanguageName: String {
        switch model.appLanguageCode {
        case "de": strings.german
        case "en": strings.english
        default: String(localized: "System")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        settingsSection(strings.about) {
            NavigationLink {
                InfoView(model: model)
            } label: {
                SettingsRow(
                    title: strings.infoTitle,
                    subtitle: strings.capabilities,
                    theme: theme
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        settingsSection(strings.support) {
            Button {
                openAppStoreReview()
            } label: {
                SettingsRow(
                    title: strings.rateApp,
                    subtitle: strings.rateAppSubtitle,
                    theme: theme
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - App Information

    private var appInfoSection: some View {
        settingsSection(strings.appInfo) {
            VStack(spacing: 24) {
                LabeledContent(
                    strings.version,
                    value: AppBuildInfo.version
                )

                Divider()
                    .overlay(theme.border)

                LabeledContent(
                    strings.build,
                    value: AppBuildInfo.build
                )
            }
            .font(.body)
            .padding()
        }
    }

    // MARK: - Section

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    theme.panelBackground,
                )
        }
    }

    // MARK: - Actions

    private func openAppStoreReview() {
        guard let appStoreReviewURL else {
            return
        }

        openURL(appStoreReviewURL)
    }
}

private struct AISettingsSection: View {
    let model: EditorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Khyra AI")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(model.selectedTheme.secondaryText)

            HStack(spacing: 12) {
                Image(systemName: "apple.intelligence")
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.body.weight(.medium))
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(model.selectedTheme.secondaryText)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(
                model.selectedTheme.panelBackground,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }

    private var statusTitle: String {
        guard #available(iOS 26.0, *) else {
            return localized("Requires iOS 26")
        }
        #if canImport(FoundationModels)
            switch SystemLanguageModel.default.availability {
            case .available:
                return localized("Ready")
            case .unavailable(.deviceNotEligible):
                return localized("Device not supported")
            case .unavailable(.appleIntelligenceNotEnabled):
                return localized("Apple Intelligence disabled")
            case .unavailable(.modelNotReady):
                return localized("Model is getting ready")
            case .unavailable:
                return localized("Unavailable")
            }
        #else
            return localized("Unavailable")
        #endif
    }

    private var statusMessage: String {
        localized("Processing happens privately on device.")
    }

    private var statusColor: Color {
        statusTitle == localized("Ready")
            ? model.selectedTheme.success
            : model.selectedTheme.warning
    }

    private func localized(_ resource: String.LocalizationValue) -> String {
        String(localized: resource, locale: model.appLocale)
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let title: String
    let subtitle: String
    let theme: EditorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(theme.primaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
        .padding()
    }
}

// MARK: - Info View

struct InfoView: View {
    let model: EditorModel

    private var strings: AppStrings {
        model.appStrings
    }

    private var theme: EditorTheme {
        model.selectedTheme
    }

    private var capabilities: [String] {
        [
            strings.infoEditor,
            strings.infoProjects,
            strings.infoPreview,
            strings.infoDocs,
            strings.infoPlayground,
            strings.infoNative,
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(strings.infoDescription)
                    .font(.body)
                    .foregroundStyle(theme.secondaryText)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(
                        Array(capabilities.enumerated()),
                        id: \.offset
                    ) { index, capability in
                        Text(capability)
                            .font(.body)
                            .foregroundStyle(theme.primaryText)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(16)

                        if index < capabilities.count - 1 {
                            Divider()
                                .overlay(theme.border)
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    theme.panelBackground,
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
            }
            .padding(20)
        }
        .background {
            theme.background
                .ignoresSafeArea()
        }
        .navigationTitle(strings.infoTitle)
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(theme.primaryText)
        .tint(theme.accent)
        .preferredColorScheme(theme.preferredScheme)
    }
}

// MARK: - Build Information

enum AppBuildInfo {
    static var version: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?[
            "CFBundleVersion"
        ] as? String ?? "1"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(model: EditorModel())
    }
}
