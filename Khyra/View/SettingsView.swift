//
//  SettingsView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct SettingsView: View {
    let model: EditorModel

    private var strings: AppStrings {
        model.appStrings
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

    private var selectedLanguageName: String {
        model.appLanguageCode == "de" ? strings.german : strings.english
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsSection(
                    title: strings.appearance,
                    systemImage: "paintpalette"
                ) {
                    Picker(selection: themeSelection) {
                        ForEach(EditorTheme.all) { theme in
                            Text(theme.name).tag(theme.id)
                        }
                    } label: {
                        SettingsRow(
                            title: strings.theme,
                            value: model.selectedTheme.name,
                            systemImage: "paintpalette",
                            showsChevron: true,
                            theme: model.selectedTheme
                        )
                    }
                    .pickerStyle(.navigationLink)
                    .tint(model.selectedTheme.accent)
                }

                settingsSection(title: strings.language, systemImage: "globe") {
                    Picker(selection: languageSelection) {
                        Text(strings.german).tag("de")
                        Text(strings.english).tag("en")
                    } label: {
                        SettingsRow(
                            title: strings.language,
                            value: selectedLanguageName,
                            systemImage: "globe",
                            showsChevron: true,
                            theme: model.selectedTheme
                        )
                    }
                    .pickerStyle(.navigationLink)
                    .tint(model.selectedTheme.accent)
                }

                settingsSection(
                    title: strings.about,
                    systemImage: "info.circle"
                ) {
                    NavigationLink {
                        InfoView(model: model)
                    } label: {
                        SettingsRow(
                            title: strings.infoTitle,
                            value: strings.capabilities,
                            systemImage: "book.closed",
                            showsChevron: true,
                            theme: model.selectedTheme
                        )
                    }
                    .buttonStyle(.plain)
                }

                settingsSection(
                    title: strings.appInfo,
                    systemImage: "app.badge"
                ) {
                    SettingsRow(
                        title: strings.version,
                        value: AppBuildInfo.version,
                        systemImage: "number",
                        showsChevron: false,
                        theme: model.selectedTheme
                    )
                    SettingsRow(
                        title: strings.build,
                        value: AppBuildInfo.build,
                        systemImage: "hammer",
                        showsChevron: false,
                        theme: model.selectedTheme
                    )
                }
            }
            .padding(16)
        }
        .background(model.selectedTheme.background)
        .foregroundStyle(model.selectedTheme.primaryText)
        .navigationTitle(strings.settings)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(model.selectedTheme.preferredScheme)
    }

    private func settingsSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                .foregroundStyle(model.selectedTheme.accent)

            VStack(spacing: 8) {
                content()
            }
            .padding(12)
            .background(
                model.selectedTheme.panelBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(model.selectedTheme.border, lineWidth: 1)
            )
        }
    }
}

struct InfoView: View {
    let model: EditorModel

    private var strings: AppStrings {
        model.appStrings
    }

    private var capabilities: [(String, String)] {
        [
            ("chevron.left.forwardslash.chevron.right", strings.infoEditor),
            ("folder", strings.infoProjects),
            ("safari", strings.infoPreview),
            ("book", strings.infoDocs),
            ("play.square", strings.infoPlayground),
            ("apple.logo", strings.infoNative),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(strings.infoDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(model.selectedTheme.secondaryText)

                VStack(spacing: 10) {
                    ForEach(capabilities, id: \.1) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.0)
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundStyle(model.selectedTheme.accent)
                                .frame(width: 26)
                            Text(item.1)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    model.selectedTheme.primaryText
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(
                            model.selectedTheme.panelBackground,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    model.selectedTheme.border,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(model.selectedTheme.background)
        .navigationTitle(strings.infoTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    let systemImage: String
    let showsChevron: Bool
    let theme: EditorTheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(theme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(
                        .system(size: 13, weight: .heavy, design: .monospaced)
                    )
                Text(value)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(
            theme.controlBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

enum AppBuildInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: EditorModel())
    }
}
