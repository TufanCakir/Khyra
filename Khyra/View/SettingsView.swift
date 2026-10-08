//
//  SettingsView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

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
                Text(strings.german)
                    .tag("de")

                Text(strings.english)
                    .tag("en")
            } label: {
                SettingsRow(
                    title: strings.language,
                    subtitle: model.appLanguageCode == "de"
                        ? strings.german
                        : strings.english,
                    theme: theme
                )
            }
            .pickerStyle(.menu)
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
