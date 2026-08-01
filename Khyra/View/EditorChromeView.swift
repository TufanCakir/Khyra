//
//  EditorChromeView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct SuggestionsBarView: View {
    let suggestions: [CodeSuggestion]
    let theme: EditorTheme
    let onSelect: (CodeSuggestion) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions) { suggestion in
                        Button {
                            onSelect(suggestion)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: suggestion.kind.iconName)
                                    .font(.system(size: 12, weight: .bold))
                                Text(suggestion.title)
                                    .font(
                                        .system(
                                            size: 12,
                                            weight: .bold,
                                            design: .monospaced
                                        )
                                    )
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.selectedText)
                        .background(
                            theme.controlBackground,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(theme.panelBackground)
        }
    }
}

struct LanguageTabsView: View {
    let languages: [CodeLanguage]
    @Binding var selectedLanguageID: String
    let theme: EditorTheme
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(languages) { language in
                    LanguageTabButton(
                        language: language,
                        isSelected: language.id == selectedLanguageID,
                        theme: theme
                    ) {
                        onSelect(language.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(theme.toolbarBackground)
    }
}

struct LanguageTabButton: View {
    let language: CodeLanguage
    let isSelected: Bool
    let theme: EditorTheme
    let action: () -> Void

    private var foregroundColor: Color {
        isSelected ? theme.selectedText : theme.secondaryText
    }

    private var backgroundColor: Color {
        isSelected ? theme.accent.opacity(0.22) : theme.controlBackground
    }

    private var borderColor: Color {
        isSelected ? theme.accent : theme.border
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                Text(language.name)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch language.id {
        case "html": "chevron.left.forwardslash.chevron.right"
        case "css": "paintbrush.pointed.fill"
        case "javascript": "curlybraces"
        default: "doc.text"
        }
    }
}

struct EditorHeaderView: View {
    let language: CodeLanguage
    let issueCount: Int
    let lineCount: Int
    let theme: EditorTheme
    let strings: AppStrings

    private var issueIconName: String {
        issueCount == 0 ? "checkmark.circle" : "exclamationmark.triangle"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundStyle(theme.accent)
            Text(language.fileExtension)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
            Spacer()
            Label("\(lineCount) \(strings.lines)", systemImage: "number")
            Label(
                "\(issueCount) \(strings.issueCount)",
                systemImage: issueIconName
            )
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(theme.secondaryText)
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(theme.panelBackground)
    }
}
