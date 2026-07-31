//
//  ConsoleView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct ConsoleView: View {
    let issues: [LintIssue]
    let theme: EditorTheme
    var onToggle: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onToggle?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundStyle(theme.accent)
                    Text("Terminal")
                        .font(
                            .system(
                                size: 14,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                    Spacer()
                    Text(issues.isEmpty ? "clean" : "\(issues.count) issue")
                        .font(
                            .system(
                                size: 12,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(
                            issues.isEmpty ? theme.success : theme.warning
                        )
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
            }
            .buttonStyle(.plain)
            .background(theme.consoleHeader)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if issues.isEmpty {
                        ConsoleLine(
                            icon: "checkmark.circle.fill",
                            text: "No lint errors found.",
                            color: theme.success
                        )
                    } else {
                        ForEach(issues) { issue in
                            ConsoleLine(
                                icon: issue.severity.iconName,
                                text: "line \(issue.line): \(issue.message)",
                                color: issue.severity.color(in: theme)
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .background(theme.consoleBackground)
        }
    }
}

struct ConsoleCollapsedBar: View {
    let theme: EditorTheme
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .foregroundStyle(theme.accent)
                Text("Terminal")
                    .font(
                        .system(size: 14, weight: .heavy, design: .monospaced)
                    )
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(theme.consoleHeader)
    }
}

struct SaveToast: View {
    let theme: EditorTheme

    var body: some View {
        Label("Saved", systemImage: "checkmark.circle.fill")
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .padding(.horizontal, 14)
            .frame(height: 40)
            .foregroundStyle(theme.selectedText)
            .background(
                theme.panelBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.success.opacity(0.7), lineWidth: 1)
            )
    }
}

struct ConsoleLine: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
