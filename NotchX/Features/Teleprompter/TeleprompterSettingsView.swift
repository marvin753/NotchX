//
//  TeleprompterSettingsView.swift
//  NotchX
//
//  Settings section for the teleprompter feature.
//

import Defaults
import SwiftUI

struct TeleprompterSettingsView: View {
    @Default(.teleprompterEnabled) private var enabled
    @Default(.teleprompterListeningMode) private var listeningMode
    @Default(.teleprompterSpeechLocale) private var speechLocale
    @Default(.teleprompterSelectedMicUID) private var selectedMicUID
    @Default(.teleprompterScrollSpeed) private var scrollSpeed
    @Default(.teleprompterFontFamily) private var fontFamily
    @Default(.teleprompterFontSize) private var fontSize
    @Default(.teleprompterFontColor) private var fontColor

    @State private var availableMics: [AudioInputDevice] = []
    @State private var availableLocales: [Locale] = []

    var body: some View {
        Form {
            Defaults.Toggle(key: .teleprompterEnabled) {
                Text("Enable Teleprompter")
            }

            if enabled {
                Button("Open Teleprompter Editor") {
                    TeleprompterEditorWindowController.shared.showWindow()
                }

                Section("Guidance Mode") {
                    Picker("Mode", selection: $listeningMode) {
                        ForEach(TeleprompterListeningMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Text(listeningMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if listeningMode != .wordTracking {
                    Section("Scroll Speed") {
                        HStack {
                            Text("Slow")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $scrollSpeed, in: 0.5...10.0, step: 0.5)
                            Text("Fast")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(scrollSpeed, specifier: "%.1f") words/sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Speech Recognition") {
                    Picker("Language", selection: $speechLocale) {
                        ForEach(availableLocales, id: \.identifier) { locale in
                            Text(
                                locale.localizedString(forIdentifier: locale.identifier)
                                    ?? locale.identifier
                            )
                            .tag(locale.identifier)
                        }
                    }

                    Picker("Microphone", selection: $selectedMicUID) {
                        Text("System Default").tag("")
                        ForEach(availableMics) { mic in
                            Text(mic.name).tag(mic.uid)
                        }
                    }
                }

                Section("Font") {
                    Picker("Family", selection: $fontFamily) {
                        ForEach(TeleprompterFontFamily.allCases, id: \.self) { family in
                            Text(family.rawValue).tag(family)
                        }
                    }

                    Picker("Size", selection: $fontSize) {
                        ForEach(TeleprompterFontSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }

                    Picker("Highlight Color", selection: $fontColor) {
                        ForEach(TeleprompterFontColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 12, height: 12)
                                Text(color.label)
                            }
                            .tag(color)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            availableMics = AudioInputDevice.allInputDevices()
            availableLocales = SpeechLocaleProvider.supportedLocales()
        }
    }
}

// MARK: - Locale provider

private enum SpeechLocaleProvider {
    static func supportedLocales() -> [Locale] {
        let identifiers = Array(
            Set(
                Locale.availableIdentifiers.filter { id in
                    let locale = Locale(identifier: id)
                    return locale.language.languageCode != nil
                }
            )
        ).sorted()

        var seen = Set<String>()
        var result: [Locale] = []
        for id in identifiers {
            let locale = Locale(identifier: id)
            let key =
                "\(locale.language.languageCode?.identifier ?? "")-\(locale.region?.identifier ?? "")"
            if seen.insert(key).inserted {
                result.append(locale)
            }
        }
        return result.sorted {
            ($0.localizedString(forIdentifier: $0.identifier) ?? $0.identifier)
                < ($1.localizedString(forIdentifier: $1.identifier) ?? $1.identifier)
        }
    }
}
