//
//  CodeDiff.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import Foundation

struct CodeDiffLine: Identifiable, Equatable {
    enum Kind: Equatable {
        case unchanged
        case added
        case removed
    }

    let id: Int
    let kind: Kind
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let text: String
}

enum CodeDiffEngine {
    static func compare(old oldCode: String, new newCode: String)
        -> [CodeDiffLine]
    {
        let oldLines = lines(in: oldCode)
        let newLines = lines(in: newCode)

        guard oldLines.count <= 1_500, newLines.count <= 1_500 else {
            return fallbackDiff(oldLines: oldLines, newLines: newLines)
        }

        let columnCount = newLines.count + 1
        var table = Array(
            repeating: 0,
            count: (oldLines.count + 1) * columnCount
        )

        if !oldLines.isEmpty, !newLines.isEmpty {
            for oldIndex in stride(from: oldLines.count - 1, through: 0, by: -1)
            {
                for newIndex in stride(
                    from: newLines.count - 1,
                    through: 0,
                    by: -1
                ) {
                    let position = oldIndex * columnCount + newIndex
                    if oldLines[oldIndex] == newLines[newIndex] {
                        table[position] =
                            table[(oldIndex + 1) * columnCount + newIndex + 1]
                            + 1
                    } else {
                        table[position] = max(
                            table[(oldIndex + 1) * columnCount + newIndex],
                            table[oldIndex * columnCount + newIndex + 1]
                        )
                    }
                }
            }
        }

        var result: [CodeDiffLine] = []
        var oldIndex = 0
        var newIndex = 0

        while oldIndex < oldLines.count || newIndex < newLines.count {
            if oldIndex < oldLines.count,
                newIndex < newLines.count,
                oldLines[oldIndex] == newLines[newIndex]
            {
                append(
                    kind: .unchanged,
                    oldLineNumber: oldIndex + 1,
                    newLineNumber: newIndex + 1,
                    text: oldLines[oldIndex],
                    to: &result
                )
                oldIndex += 1
                newIndex += 1
            } else if newIndex < newLines.count,
                oldIndex == oldLines.count
                    || table[oldIndex * columnCount + newIndex + 1]
                        >= table[(oldIndex + 1) * columnCount + newIndex]
            {
                append(
                    kind: .added,
                    oldLineNumber: nil,
                    newLineNumber: newIndex + 1,
                    text: newLines[newIndex],
                    to: &result
                )
                newIndex += 1
            } else {
                append(
                    kind: .removed,
                    oldLineNumber: oldIndex + 1,
                    newLineNumber: nil,
                    text: oldLines[oldIndex],
                    to: &result
                )
                oldIndex += 1
            }
        }

        return result
    }

    private static func lines(in code: String) -> [String] {
        code.components(separatedBy: "\n")
    }

    private static func append(
        kind: CodeDiffLine.Kind,
        oldLineNumber: Int?,
        newLineNumber: Int?,
        text: String,
        to result: inout [CodeDiffLine]
    ) {
        result.append(
            CodeDiffLine(
                id: result.count,
                kind: kind,
                oldLineNumber: oldLineNumber,
                newLineNumber: newLineNumber,
                text: text
            )
        )
    }

    private static func fallbackDiff(
        oldLines: [String],
        newLines: [String]
    ) -> [CodeDiffLine] {
        var result: [CodeDiffLine] = []

        for (index, line) in oldLines.enumerated() {
            append(
                kind: .removed,
                oldLineNumber: index + 1,
                newLineNumber: nil,
                text: line,
                to: &result
            )
        }
        for (index, line) in newLines.enumerated() {
            append(
                kind: .added,
                oldLineNumber: nil,
                newLineNumber: index + 1,
                text: line,
                to: &result
            )
        }

        return result
    }
}
