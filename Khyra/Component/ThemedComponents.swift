//
//  ThemedComponents.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct ThemedActionButton: View {
    let title: String
    let systemImage: String
    let theme: EditorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .heavy))
                    .frame(width: 26)
                Text(title)
                    .font(
                        .system(size: 16, weight: .heavy, design: .monospaced)
                    )
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.selectedText)
        .background(
            theme.panelBackground,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

struct ThemedModal<Content: View>: View {
    let title: String
    let theme: EditorTheme
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(
                            .system(
                                size: 18,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .heavy))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.accent)
                }
                .padding(16)
                .background(theme.headerBackground)

                content()
                    .padding(16)
            }
            .frame(maxWidth: 360)
            .background(
                theme.panelBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.border, lineWidth: 1)
            )
            .padding(20)
        }
        .foregroundStyle(theme.primaryText)
    }
}
