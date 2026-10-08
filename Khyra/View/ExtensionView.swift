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

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var selectedCategory: ProjectTemplateCategory = .all
    @State private var currentPage = 0

    private let itemsPerPage = 4

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var availableCategories: [ProjectTemplateCategory] {
        ProjectTemplateCategory.allCases.filter { category in
            category == .all || templates.contains { $0.category == category }
        }
    }

    private var filteredTemplates: [ProjectTemplate] {
        guard selectedCategory != .all else {
            return templates
        }

        return templates.filter {
            $0.category == selectedCategory
        }
    }

    private var pages: [[ProjectTemplate]] {
        stride(
            from: 0,
            to: filteredTemplates.count,
            by: itemsPerPage
        ).map { start in
            Array(
                filteredTemplates[
                    start..<min(
                        start + itemsPerPage,
                        filteredTemplates.count
                    )
                ]
            )
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            categoryPicker

            if pages.isEmpty {
                ContentUnavailableView(
                    "No Templates",
                    systemImage: "square.grid.2x2"
                )
                .frame(height: 190)
            } else {
                pageNavigation

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { page in
                        templateGrid(pages[page])
                            .tag(page)
                    }
                }
                .tabViewStyle(
                    .page(indexDisplayMode: .never)
                )
                .frame(height: 188)

                if pages.count > 1 {
                    pageIndicators
                }
            }
        }
        .onChange(of: selectedCategory) {
            currentPage = 0
        }
        .onChange(of: pages.count) {
            currentPage = min(
                currentPage,
                max(0, pages.count - 1)
            )
        }
        .tint(theme.accent)
    }

    // MARK: - Categories

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(availableCategories) { category in
                Label(
                    category.title,
                    systemImage: category.systemImage
                )
                .tag(category)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page Navigation

    private var pageNavigation: some View {
        HStack(spacing: 12) {
            Text("\(currentPage + 1) / \(pages.count)")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .monospacedDigit()

            Spacer()

            Button {
                changePage(to: currentPage - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 30, height: 30)
            }
            .disabled(currentPage == 0)

            Button {
                changePage(to: currentPage + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 30, height: 30)
            }
            .disabled(currentPage >= pages.count - 1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
    }

    private func changePage(to page: Int) {
        guard pages.indices.contains(page) else {
            return
        }

        if reduceMotion {
            currentPage = page
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentPage = page
            }
        }
    }

    // MARK: - Template Grid

    private func templateGrid(
        _ items: [ProjectTemplate]
    ) -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { template in
                ProjectTemplateCard(
                    template: template,
                    theme: theme
                ) {
                    onSelect(template)
                }
            }
        }
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { page in
                Circle()
                    .fill(
                        page == currentPage
                            ? theme.accent
                            : theme.secondaryText.opacity(0.3)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Template Card

struct ProjectTemplateCard: View {
    let template: ProjectTemplate
    let theme: EditorTheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: template.systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .frame(height: 28)

                Text(template.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(template.subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .padding(6)
            .background(
                theme.controlBackground,
                in: RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .strokeBorder(
                    theme.border.opacity(0.6),
                    lineWidth: 1
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(template.title)
        .accessibilityHint(template.subtitle)
    }
}

// MARK: - Preview

#Preview {
    ExtensionView(
        templates: ProjectTemplate.catalog(
            from: LanguageStore.load()
        ),
        theme: .techDark,
        onSelect: { _ in }
    )
    .padding()
    .background(EditorTheme.techDark.background)
}
