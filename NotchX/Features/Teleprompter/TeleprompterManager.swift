//
//  TeleprompterManager.swift
//  NotchX
//
//  Central coordinator for the teleprompter feature.
//  Owns TeleprompterService, manages notch open/close via notifications,
//  and keeps SharingStateManager balanced.
//

import Combine
import Defaults
import Foundation
import Speech

@MainActor
class TeleprompterManager: ObservableObject {
    static let shared = TeleprompterManager()

    @Published var scriptText: String = ""
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var words: [String] = []
    @Published var timerWordProgress: Double = 0
    @Published var lastError: String? = nil

    let service = TeleprompterService()

    private var enabledCancellable: AnyCancellable?
    private var viewCancellable: AnyCancellable?
    private var scrollTimerCancellable: AnyCancellable?
    private var errorCancellable: AnyCancellable?
    private var charCountCancellable: AnyCancellable?
    private var isManualScrolling: Bool = false
    private var isStoppingFromNotchClose: Bool = false

    var effectiveCharCount: Int {
        switch Defaults[.teleprompterListeningMode] {
        case .wordTracking:
            return service.recognizedCharCount
        case .classic, .silencePaused:
            return charOffsetForWordProgress(timerWordProgress)
        }
    }

    private init() {
        enabledCancellable = Defaults.publisher(.teleprompterEnabled)
            .dropFirst()
            .sink { [weak self] change in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if !change.newValue {
                        if self.isActive {
                            self.stopTeleprompter()
                        }
                        if NotchXViewCoordinator.shared.currentView == .teleprompter {
                            NotchXViewCoordinator.shared.currentView = .home
                        }
                    }
                }
            }

        viewCancellable = NotchXViewCoordinator.shared.$currentView
            .dropFirst()
            .sink { [weak self] newView in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if newView != .teleprompter && self.isActive {
                        self.handleNotchClosed()
                    }
                }
            }

        // Propagate service.recognizedCharCount changes so SwiftUI re-renders
        charCountCancellable = service.$recognizedCharCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Start

    func startTeleprompter() {
        // If already active, stop first to balance activeSessions
        if isActive {
            stopTeleprompterInternal()
        }

        let text = scriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let parsedWords = splitTeleprompterWords(text)
        guard !parsedWords.isEmpty else { return }

        let mode = Defaults[.teleprompterListeningMode]

        // Pre-check speech permission for speech-dependent modes
        if mode == .wordTracking || mode == .silencePaused {
            let status = SFSpeechRecognizer.authorizationStatus()
            if status == .denied || status == .restricted {
                lastError = "Speech recognition not authorized. Open System Settings \u{2192} Privacy & Security \u{2192} Speech Recognition to allow NotchX."
                return
            }
        }

        words = parsedWords
        isActive = true
        isPaused = false
        timerWordProgress = 0
        lastError = nil

        SharingStateManager.shared.beginInteraction()

        NotchXViewCoordinator.shared.currentView = .teleprompter
        NotificationCenter.default.post(name: .teleprompterRequestOpen, object: nil)

        // Start speech service for speech-dependent modes
        if mode == .wordTracking || mode == .silencePaused {
            service.start(with: text)
        }

        // Start scroll timer for timer-based modes
        if mode == .classic || mode == .silencePaused {
            startScrollTimer()
        }

        // Observe service errors
        errorCancellable = service.$error
            .combineLatest(service.$isListening)
            .sink { [weak self] error, isListening in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error, !isListening {
                        self.lastError = error
                        self.stopTeleprompter()
                    }
                }
            }

        TeleprompterEditorWindowController.shared.hideWindow()
    }

    // MARK: - Stop

    func stopTeleprompter() {
        guard isActive else { return }
        stopTeleprompterInternal()

        if !isStoppingFromNotchClose {
            NotificationCenter.default.post(name: .teleprompterRequestClose, object: nil)
        }
    }

    private func stopTeleprompterInternal() {
        isActive = false
        isPaused = false

        service.forceStop()
        scrollTimerCancellable?.cancel()
        scrollTimerCancellable = nil
        errorCancellable?.cancel()
        errorCancellable = nil

        SharingStateManager.shared.endInteraction()
    }

    // MARK: - Pause

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            service.stop()
            scrollTimerCancellable?.cancel()
            scrollTimerCancellable = nil
        } else {
            let mode = Defaults[.teleprompterListeningMode]
            if mode == .wordTracking || mode == .silencePaused {
                service.resume()
            }
            if mode == .classic || mode == .silencePaused {
                startScrollTimer()
            }
        }
    }

    // MARK: - Notch Closed

    func handleNotchClosed() {
        guard isActive else { return }
        isStoppingFromNotchClose = true
        stopTeleprompter()
        isStoppingFromNotchClose = false
    }

    // MARK: - Manual Scroll

    func setManualScrolling(_ scrolling: Bool, progress: Double = 0) {
        if scrolling {
            isManualScrolling = true
        } else {
            timerWordProgress = progress
            isManualScrolling = false
        }
    }

    func jumpToWord(charOffset: Int) {
        service.jumpTo(charOffset: charOffset)
        let useSmoothScroll = Defaults[.teleprompterListeningMode] != .wordTracking
        if useSmoothScroll {
            timerWordProgress = wordProgressForCharOffset(charOffset)
        }
    }

    // MARK: - Timer-based scroll

    private func startScrollTimer() {
        scrollTimerCancellable?.cancel()
        scrollTimerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.isPaused, !self.isManualScrolling else { return }

                let mode = Defaults[.teleprompterListeningMode]
                let speed = Defaults[.teleprompterScrollSpeed]

                switch mode {
                case .wordTracking:
                    break
                case .classic:
                    self.timerWordProgress += speed * 0.05
                case .silencePaused:
                    if self.service.isListening && self.service.isSpeaking {
                        self.timerWordProgress += speed * 0.05
                    }
                }
            }
    }

    // MARK: - Helpers

    func charOffsetForWordProgress(_ progress: Double) -> Int {
        let wordIdx = Int(progress)
        guard !words.isEmpty else { return 0 }
        var charCount = 0
        for i in 0..<min(wordIdx, words.count) {
            charCount += words[i].count + 1
        }
        if wordIdx < words.count {
            let fraction = progress - Double(wordIdx)
            charCount += Int(Double(words[wordIdx].count) * fraction)
        }
        return min(charCount, words.joined(separator: " ").count)
    }

    private func wordProgressForCharOffset(_ charOffset: Int) -> Double {
        var offset = 0
        for (i, word) in words.enumerated() {
            let end = offset + word.count
            if charOffset <= end {
                let wordLen = max(1, word.count)
                let into = charOffset - offset
                return Double(i) + Double(into) / Double(wordLen)
            }
            offset = end + 1
        }
        return Double(words.count)
    }
}
