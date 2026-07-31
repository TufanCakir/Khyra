//
//  CodeLinter.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

enum CodeLinter {
    private static let htmlSelfClosingTags: Set<String> = {
        let tagNames =
            "area base br col embed hr img input link meta param source track wbr"
        return Set(tagNames.split(separator: " ").map(String.init))
    }()

    static func lint(_ source: String, language: CodeLanguage) -> [LintIssue] {
        var issues = commonIssues(in: source)

        switch language.id {
        case "html":
            issues.append(contentsOf: htmlIssues(in: source))
        case "css":
            issues.append(contentsOf: cssIssues(in: source))
        case "javascript":
            issues.append(contentsOf: javascriptIssues(in: source))
        default:
            break
        }

        return issues.sorted { $0.line < $1.line }
    }

    private static func commonIssues(in source: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let pairs: [(Character, Character)] = [
            ("(", ")"), ("[", "]"), ("{", "}"),
        ]

        for pair in pairs {
            let openCount = source.filter { $0 == pair.0 }.count
            let closeCount = source.filter { $0 == pair.1 }.count
            if openCount != closeCount {
                let line = lineOfLastOccurrence(pair.0, in: source)
                let message =
                    openCount > closeCount
                    ? "Missing closing '\(pair.1)' for '\(pair.0)'."
                    : "Extra closing '\(pair.1)' without matching '\(pair.0)'."
                issues.append(
                    LintIssue(line: line, severity: .error, message: message)
                )
            }
        }

        let doubleQuoteCount = source.filter { $0 == "\"" }.count
        let singleQuoteCount = source.filter { $0 == "'" }.count
        if !doubleQuoteCount.isMultiple(of: 2) {
            issues.append(
                LintIssue(
                    line: lineOfLastOccurrence("\"", in: source),
                    severity: .error,
                    message: "Unclosed double quote. Add a matching \"."
                )
            )
        }
        if !singleQuoteCount.isMultiple(of: 2) {
            issues.append(
                LintIssue(
                    line: lineOfLastOccurrence("'", in: source),
                    severity: .error,
                    message: "Unclosed single quote. Add a matching '."
                )
            )
        }

        return issues
    }

    private static func htmlIssues(in source: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        var stack: [(name: String, line: Int)] = []
        let lines = source.components(separatedBy: .newlines)
        let pattern = "<(/?)([A-Za-z][A-Za-z0-9-]*)([^>]*)>"
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return issues
        }

        for (index, line) in lines.enumerated() {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            expression.enumerateMatches(in: line, range: range) { match, _, _ in
                guard let match else { return }
                let closing = nsLine.substring(with: match.range(at: 1)) == "/"
                let name = nsLine.substring(with: match.range(at: 2))
                    .lowercased()
                let fullTag = nsLine.substring(with: match.range(at: 0))
                guard !htmlSelfClosingTags.contains(name),
                    !fullTag.hasSuffix("/>")
                else { return }

                if closing {
                    if stack.last?.name == name {
                        stack.removeLast()
                    } else {
                        let message =
                            "Unexpected </\(name)>. Add matching <\(name)> before it or remove the closing tag."
                        issues.append(
                            LintIssue(
                                line: index + 1,
                                severity: .error,
                                message: message
                            )
                        )
                    }
                } else {
                    stack.append((name, index + 1))
                }
            }
        }

        for tag in stack.suffix(3) {
            let message =
                "Missing closing tag </\(tag.name)> for <\(tag.name)>."
            issues.append(
                LintIssue(line: tag.line, severity: .error, message: message)
            )
        }

        return issues
    }

    private static func cssIssues(in source: String) -> [LintIssue] {
        source.components(separatedBy: .newlines).enumerated().compactMap {
            index,
            rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.contains(":"), !line.hasSuffix(";"), !line.hasSuffix("{")
            else { return nil }
            return LintIssue(
                line: index + 1,
                severity: .warning,
                message: "CSS declaration should end with ';'."
            )
        }
    }

    private static func javascriptIssues(in source: String) -> [LintIssue] {
        source.components(separatedBy: .newlines).enumerated().compactMap {
            index,
            rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("var ") else { return nil }
            return LintIssue(
                line: index + 1,
                severity: .warning,
                message: "Avoid 'var'. Use 'let' or 'const' instead."
            )
        }
    }

    private static func lineOfLastOccurrence(
        _ character: Character,
        in source: String
    ) -> Int {
        var line = 1
        var currentLine = 1
        for value in source {
            if value == character { line = currentLine }
            if value == "\n" { currentLine += 1 }
        }
        return line
    }
}

struct LintIssue: Identifiable, Equatable {
    let id = UUID()
    let line: Int
    let severity: LintSeverity
    let message: String
}

enum LintSeverity: Equatable {
    case error
    case warning

    var iconName: String {
        switch self {
        case .error: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    func color(in theme: EditorTheme) -> Color {
        switch self {
        case .error: theme.error
        case .warning: theme.warning
        }
    }
}
