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
            NXStyledToggle(title: "Enable Teleprompter", key: .teleprompterEnabled)

            if enabled {
                Button("Open Teleprompter Editor") {
                    TeleprompterEditorWindowController.shared.showWindow()
                }

                Section {
                    NXSegmentedControl(
                        items: [
                            NXSegmentItem(label: "Word Tracking", value: TeleprompterListeningMode.wordTracking, content: .animatedIcon("text.magnifyingglass", .pulse)),
                            NXSegmentItem(label: "Classic", value: TeleprompterListeningMode.classic, content: .icon("arrow.down")),
                            NXSegmentItem(label: "Voice-Activated", value: TeleprompterListeningMode.silencePaused, content: .animatedIcon("mic", .pulse)),
                        ],
                        selection: $listeningMode
                    )

                    Text(listeningMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    NXSectionHeader(title: "Guidance Mode")
                }

                if listeningMode == .classic {
                    Section {
                        NXStyledSlider(
                            value: $scrollSpeed,
                            title: "Scroll Speed",
                            range: 0.5...10.0,
                            step: 0.5,
                            unit: " w/s",
                            minLabel: "Slow",
                            maxLabel: "Fast"
                        )
                    } header: {
                        NXSectionHeader(title: "Scroll Speed")
                    }
                }

                Section {
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
                } header: {
                    NXSectionHeader(title: "Speech Recognition")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Font style")
                            .font(.body)

                        NXVisualPreviewPicker(
                            items: [
                                NXPreviewItem(label: "Sans", value: TeleprompterFontFamily.sans) {
                                    Text("Ag").font(.system(size: 28, weight: .semibold, design: .default))
                                },
                                NXPreviewItem(label: "Serif", value: TeleprompterFontFamily.serif) {
                                    Text("Ag").font(.system(size: 28, weight: .semibold, design: .serif))
                                },
                                NXPreviewItem(label: "Mono", value: TeleprompterFontFamily.mono) {
                                    Text("Ag").font(.system(size: 28, weight: .semibold, design: .monospaced))
                                },
                                NXPreviewItem(label: "Dyslexia", value: TeleprompterFontFamily.dyslexia) {
                                    Text("Ag").font(Font.custom("OpenDyslexicThree-Regular", size: 28).weight(.semibold))
                                },
                            ],
                            selection: $fontFamily,
                            cardHeight: 60,
                            iconSize: 22
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Font size")
                            .font(.body)

                        NXVisualPreviewPicker(
                            items: [
                                NXPreviewItem(label: "XS", value: TeleprompterFontSize.xs) {
                                    Text("Ag").font(.system(size: 18, weight: .semibold))
                                },
                                NXPreviewItem(label: "S", value: TeleprompterFontSize.sm) {
                                    Text("Ag").font(.system(size: 24, weight: .semibold))
                                },
                                NXPreviewItem(label: "L", value: TeleprompterFontSize.lg) {
                                    Text("Ag").font(.system(size: 32, weight: .semibold))
                                },
                                NXPreviewItem(label: "XL", value: TeleprompterFontSize.xl) {
                                    Text("Ag").font(.system(size: 40, weight: .semibold))
                                },
                            ],
                            selection: $fontSize,
                            cardHeight: 60,
                            iconSize: 22
                        )
                    }

                    NXIconGridPicker(
                        items: TeleprompterFontColor.allCases.map {
                            NXIconGridItem(label: $0.label, value: $0, color: $0.color)
                        },
                        selection: $fontColor
                    )
                } header: {
                    NXSectionHeader(title: "Font")
                }
            }
        }
        .formStyle(.grouped)
        .accentColor(Color.effectiveAccent)
        .navigationTitle("Teleprompter")
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
