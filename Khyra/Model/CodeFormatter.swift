//
//  CodeFormatter.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

enum CodeFormatter {
    static func format(_ source: String, language: CodeLanguage) -> String {
        switch language.id {
        case "html":
            formatMarkup(source)
        case "css", "javascript":
            formatBracedCode(source)
        default:
            source
        }
    }

    private static func formatMarkup(_ source: String) -> String {
        let normalized = source.replacingOccurrences(of: "><", with: ">\n<")
        let lines = normalized.components(separatedBy: .newlines)
        var indentLevel = 0
        var formattedLines: [String] = []

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("</") {
                indentLevel = max(0, indentLevel - 1)
            }

            formattedLines.append(
                String(repeating: "  ", count: indentLevel) + line
            )

            if isOpeningMarkupLine(line) {
                indentLevel += 1
            }
        }

        return formattedLines.joined(separator: "\n")
    }

    private static func isOpeningMarkupLine(_ line: String) -> Bool {
        guard line.hasPrefix("<"),
            !line.hasPrefix("</"),
            !line.hasPrefix("<!"),
            !line.hasSuffix("/>")
        else {
            return false
        }

        let singleLineTags = [
            "area", "base", "br", "col", "embed", "hr", "img", "input", "link",
            "meta", "param", "source", "track", "wbr",
        ]
        let lowercasedLine = line.lowercased()
        if singleLineTags.contains(where: { lowercasedLine.hasPrefix("<\($0)") }
        ) {
            return false
        }

        guard let tagName = tagName(in: line) else { return false }
        return !lowercasedLine.contains("</\(tagName)>")
    }

    private static func tagName(in line: String) -> String? {
        guard line.hasPrefix("<") else { return nil }
        let afterBracket = line.dropFirst()
        let name = afterBracket.prefix { character in
            character.isLetter || character.isNumber || character == "-"
        }
        return name.isEmpty ? nil : String(name).lowercased()
    }

    private static func formatBracedCode(_ source: String) -> String {
        var result = ""
        var indentLevel = 0
        var pendingWhitespace = false

        for character in source {
            switch character {
            case "{":
                result = result.trimmedRight + " {\n"
                indentLevel += 1
                result += indentation(indentLevel)
                pendingWhitespace = false
            case "}":
                indentLevel = max(0, indentLevel - 1)
                result =
                    result.trimmedRight + "\n" + indentation(indentLevel) + "}"
                pendingWhitespace = false
            case ";":
                result = result.trimmedRight + ";\n" + indentation(indentLevel)
                pendingWhitespace = false
            case "\n", "\t", " ":
                pendingWhitespace = !result.hasSuffix("\n")
            default:
                if pendingWhitespace && !result.hasSuffix(" ")
                    && !result.hasSuffix("\n")
                {
                    result += " "
                }
                result.append(character)
                pendingWhitespace = false
            }
        }

        return
            result
            .components(separatedBy: .newlines)
            .map { $0.trimmedRight }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func indentation(_ level: Int) -> String {
        String(repeating: "  ", count: level)
    }
}

extension String {
    fileprivate var trimmedRight: String {
        var value = self
        while value.last == " " || value.last == "\t" {
            value.removeLast()
        }
        return value
    }
}
