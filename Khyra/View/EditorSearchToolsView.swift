//
//  EditorSearchToolsView.swift
//  Khyra
//
//  Created by Tufan Cakir on 31.07.26.
//

import SwiftUI

struct EditorSearchToolsView: View {
    @Binding var code: String
    @Binding var cursorLocation: Int
    @Binding var selectionLength: Int

    let isGerman: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var replacement = ""
    @State private var isCaseSensitive = false
    @State private var status = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(isGerman ? "Suchen" : "Find") {
                    TextField(
                        isGerman ? "Suchtext" : "Search text",
                        text: $query
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Toggle(
                        isGerman ? "Groß-/Kleinschreibung" : "Case sensitive",
                        isOn: $isCaseSensitive
                    )

                    Button {
                        findNext()
                    } label: {
                        Label(
                            isGerman ? "Nächster Treffer" : "Find next",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .disabled(query.isEmpty)
                }

                Section(isGerman ? "Ersetzen" : "Replace") {
                    TextField(
                        isGerman ? "Ersetzen durch" : "Replace with",
                        text: $replacement
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        replaceCurrent()
                    } label: {
                        Label(
                            isGerman ? "Treffer ersetzen" : "Replace match",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(query.isEmpty)

                    Button {
                        replaceAll()
                    } label: {
                        Label(
                            isGerman ? "Alle ersetzen" : "Replace all",
                            systemImage: "text.badge.checkmark"
                        )
                    }
                    .disabled(query.isEmpty)
                }

                if !status.isEmpty {
                    Section {
                        Text(status)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(isGerman ? "Suchen & Ersetzen" : "Find & Replace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isGerman ? "Fertig" : "Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var compareOptions: NSString.CompareOptions {
        isCaseSensitive ? [] : .caseInsensitive
    }

    private func findNext() {
        let source = code as NSString
        guard source.length > 0 else {
            status = isGerman ? "Dokument ist leer." : "Document is empty."
            return
        }

        let start = min(
            cursorLocation + selectionLength,
            source.length
        )
        var match = source.range(
            of: query,
            options: compareOptions,
            range: NSRange(location: start, length: source.length - start)
        )

        if match.location == NSNotFound, start > 0 {
            match = source.range(
                of: query,
                options: compareOptions,
                range: NSRange(location: 0, length: start)
            )
        }

        guard match.location != NSNotFound else {
            selectionLength = 0
            status = isGerman ? "Kein Treffer gefunden." : "No match found."
            return
        }

        cursorLocation = match.location
        selectionLength = match.length
        status =
            isGerman
            ? "Treffer in Zeile \(lineNumber(at: match.location))."
            : "Match on line \(lineNumber(at: match.location))."
    }

    private func replaceCurrent() {
        let source = code as NSString
        let selection = NSRange(
            location: cursorLocation,
            length: selectionLength
        )

        guard selection.length > 0,
            NSMaxRange(selection) <= source.length,
            source.substring(with: selection).compare(
                query,
                options: isCaseSensitive ? [] : .caseInsensitive
            ) == .orderedSame,
            let swiftRange = Range(selection, in: code)
        else {
            findNext()
            return
        }

        code.replaceSubrange(swiftRange, with: replacement)
        cursorLocation = selection.location
        selectionLength = replacement.utf16.count
        status = isGerman ? "Treffer ersetzt." : "Match replaced."
    }

    private func replaceAll() {
        var searchLocation = 0
        var result = code
        var replacementCount = 0

        while searchLocation <= (result as NSString).length {
            let source = result as NSString
            let searchRange = NSRange(
                location: searchLocation,
                length: source.length - searchLocation
            )
            let match = source.range(
                of: query,
                options: compareOptions,
                range: searchRange
            )
            guard match.location != NSNotFound,
                let swiftRange = Range(match, in: result)
            else {
                break
            }

            result.replaceSubrange(swiftRange, with: replacement)
            searchLocation = match.location + replacement.utf16.count
            replacementCount += 1
        }

        code = result
        cursorLocation = min(cursorLocation, result.utf16.count)
        selectionLength = 0
        status =
            isGerman
            ? "\(replacementCount) Treffer ersetzt."
            : "\(replacementCount) matches replaced."
    }

    private func lineNumber(at utf16Offset: Int) -> Int {
        let source = code as NSString
        let prefix = source.substring(
            with: NSRange(location: 0, length: min(utf16Offset, source.length))
        )
        return prefix.reduce(1) { count, character in
            character == "\n" ? count + 1 : count
        }
    }
}

struct GoToLineView: View {
    @Binding var cursorLocation: Int
    @Binding var selectionLength: Int

    let code: String
    let isGerman: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var lineText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    isGerman ? "Zeilennummer" : "Line number",
                    text: $lineText
                )
                .keyboardType(.numberPad)

                Button {
                    goToLine()
                } label: {
                    Label(
                        isGerman ? "Zur Zeile springen" : "Go to line",
                        systemImage: "arrow.right.to.line"
                    )
                }
                .disabled(Int(lineText) == nil)
            }
            .navigationTitle(isGerman ? "Gehe zu Zeile" : "Go to Line")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isGerman ? "Abbrechen" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    private func goToLine() {
        guard let requestedLine = Int(lineText) else { return }
        let targetLine = max(1, requestedLine)
        let source = code as NSString
        var line = 1
        var location = 0

        while line < targetLine && location < source.length {
            let range = source.range(
                of: "\n",
                range: NSRange(
                    location: location,
                    length: source.length - location
                )
            )
            guard range.location != NSNotFound else {
                location = source.length
                break
            }
            location = NSMaxRange(range)
            line += 1
        }

        cursorLocation = location
        selectionLength = 0
        dismiss()
    }
}
