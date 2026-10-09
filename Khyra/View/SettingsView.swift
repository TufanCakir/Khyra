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
        Form {
            Section(strings.appearance) {
                Picker(strings.theme, selection: themeSelection) {
                    ForEach(EditorTheme.all) { item in
                        Text(item.name)
                            .tag(item.id)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(strings.language) {
                Picker(strings.language, selection: languageSelection) {
                    Text("System")
                        .tag("system")
                    Text(strings.german)
                        .tag("de")
                    Text(strings.english)
                        .tag("en")
                }
                .pickerStyle(.menu)
            }

            Section("Khyra AI") {
                AISettingsRow(model: model)
            }

            Section(strings.about) {
                NavigationLink {
                    InfoView(model: model)
                } label: {
                    SettingsNavigationLabel(
                        title: strings.infoTitle,
                        subtitle: strings.capabilities,
                        theme: theme
                    )
                }
            }

            Section(strings.support) {
                Button(action: openAppStoreReview) {
                    SettingsNavigationLabel(
                        title: strings.rateApp,
                        subtitle: strings.rateAppSubtitle,
                        theme: theme
                    )
                }
            }

            Section(strings.appInfo) {
                LabeledContent(strings.version, value: AppBuildInfo.version)
                LabeledContent(strings.build, value: AppBuildInfo.build)
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, 88)
        .background(theme.background.ignoresSafeArea())
        .listRowBackground(theme.panelBackground)
        .foregroundStyle(theme.primaryText)
        .tint(theme.accent)
        .navigationTitle(strings.settings)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(theme.preferredScheme)
    }

    // MARK: - Actions

    private func openAppStoreReview() {
        guard let appStoreReviewURL else {
            return
        }

        openURL(appStoreReviewURL)
    }
}

private struct AISettingsRow: View {
    let model: EditorModel

    var body: some View {
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

// MARK: - Settings Navigation Label

private struct SettingsNavigationLabel: View {
    let title: String
    let subtitle: String
    let theme: EditorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(theme.primaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
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
