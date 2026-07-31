//
//  ExtensionView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct ExtensionView: View {
    let templates: [ProjectTemplate]
    let theme: EditorTheme
    let onSelect: (ProjectTemplate) -> Void
    @State private var selectedCategory: ProjectTemplateCategory = .all

    private var availableCategories: [ProjectTemplateCategory] {
        ProjectTemplateCategory.allCases.filter { category in
            category == .all || templates.contains { $0.category == category }
        }
    }

    private var filteredTemplates: [ProjectTemplate] {
        if selectedCategory == .all {
            return templates
        }
        return templates.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 12) {
            categoryTabs

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredTemplates) { template in
                        ProjectTemplateCard(
                            template: template,
                            theme: theme
                        ) {
                            onSelect(template)
                        }
                    }
                }
            }
            .frame(maxHeight: 430)
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableCategories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 12, weight: .heavy))
                            Text(category.title)
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .heavy,
                                        design: .monospaced
                                    )
                                )
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        selectedCategory == category
                            ? theme.selectedText : theme.secondaryText
                    )
                    .background(
                        selectedCategory == category
                            ? theme.accent.opacity(0.22)
                            : theme.controlBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedCategory == category
                                    ? theme.accent : theme.border,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
}

struct ProjectTemplateCard: View {
    let template: ProjectTemplate
    let theme: EditorTheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: template.systemImage)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(theme.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 5) {
                    Text(template.title)
                        .font(
                            .system(
                                size: 14,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)

                    Text(template.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(2)

                    Text(
                        "\(template.files.count) file\(template.files.count == 1 ? "" : "s")"
                    )
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.accent)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
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

#Preview {
    ExtensionView(
        templates: ProjectTemplate.catalog(from: LanguageStore.load()),
        theme: .techDark,
        onSelect: { _ in }
    )
    .padding()
    .background(EditorTheme.techDark.background)
}
