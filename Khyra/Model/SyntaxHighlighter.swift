//
//  SyntaxHighlighter.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI
import UIKit

enum SyntaxHighlighter {
    static func highlight(
        _ source: String,
        language: CodeLanguage,
        theme: EditorTheme
    ) -> NSAttributedString {
        let text = source as NSString
        let attributed = NSMutableAttributedString(
            string: source,
            attributes: [
                .font: UIFont.monospacedSystemFont(
                    ofSize: 15,
                    weight: .regular
                ),
                .foregroundColor: UIColor(theme.codeText),
            ]
        )

        apply(
            pattern: "//.*|/\\*[\\s\\S]*?\\*/|<!--(?:.|\\n)*?-->",
            color: theme.comment,
            in: text,
            attributed: attributed
        )
        apply(
            pattern: "\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'",
            color: theme.string,
            in: text,
            attributed: attributed
        )
        apply(
            pattern: "\\b\\d+(?:\\.\\d+)?\\b",
            color: theme.number,
            in: text,
            attributed: attributed
        )

        if language.id == "html" || language.id == "php" {
            apply(
                pattern: "</?[A-Za-z][A-Za-z0-9-]*|/?>",
                color: theme.tag,
                in: text,
                attributed: attributed
            )
            apply(
                pattern: "<\\?php|<\\?=|\\?>",
                color: theme.keyword,
                in: text,
                attributed: attributed
            )
        }

        for keyword in language.keywords {
            let escaped = NSRegularExpression.escapedPattern(for: keyword)
            let pattern =
                language.id == "html"
                ? "(?<=<|\\s)\\b\(escaped)\\b" : "\\b\(escaped)\\b"
            apply(
                pattern: pattern,
                color: theme.keyword,
                in: text,
                attributed: attributed
            )
        }

        return attributed
    }

    private static func apply(
        pattern: String,
        color: Color,
        in text: NSString,
        attributed: NSMutableAttributedString
    ) {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return
        }
        let range = NSRange(location: 0, length: text.length)
        expression.enumerateMatches(in: text as String, range: range) {
            match,
            _,
            _ in
            guard let match else { return }
            attributed.addAttribute(
                .foregroundColor,
                value: UIColor(color),
                range: match.range
            )
        }
    }
}
