//
//  TeleprompterModule.swift
//  NotchX
//
//  Notch view for the teleprompter feature.
//  Shows an empty state with "Open Editor" when inactive,
//  and the active scrolling display when running.
//

import Defaults
import SwiftUI

struct TeleprompterModule: View {
    @ObservedObject private var manager = TeleprompterManager.shared
    @Default(.teleprompterListeningMode) private var listeningMode
    @Default(.teleprompterFontFamily) private var fontFamily
    @Default(.teleprompterFontSize) private var fontSize
    @Default(.teleprompterFontColor) private var fontColor

    private var useSmoothScroll: Bool {
        listeningMode == .classic || listeningMode == .silencePaused
    }

    private var teleprompterFont: NSFont {
        fontFamily.font(size: fontSize.pointSize)
    }

    var body: some View {
        Group {
            if manager.isPreviewMode {
                previewView
            } else if manager.isActive {
                activeView
            } else {
                emptyStateView
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.word.spacing")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.3))

            Text("Teleprompter")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Button(action: {
                TeleprompterEditorWindowController.shared.showWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                    Text("Open Editor")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview View

    private var previewView: some View {
        ZStack(alignment: .topTrailing) {
            SpeechScrollView(
                words: manager.previewWords,
                highlightedCharCount: manager.previewEffectiveCharCount,
                font: teleprompterFont,
                highlightColor: fontColor.color,
                onWordTap: nil,
                onManualScroll: { scrolling, progress in
                    manager.setPreviewManualScrolling(scrolling, progress: progress)
                },
                smoothScroll: useSmoothScroll,
                smoothWordProgress: manager.previewWordProgress,
                isListening: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            previewBadge
                .padding(8)
        }
    }

    private var previewBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.system(size: 9))
            Text("Preview")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Active View

    private var activeView: some View {
        VStack(spacing: 0) {
            SpeechScrollView(
                words: manager.words,
                highlightedCharCount: manager.effectiveCharCount,
                font: teleprompterFont,
                highlightColor: fontColor.color,
                onWordTap: { charOffset in
                    manager.jumpToWord(charOffset: charOffset)
                },
                onManualScroll: { scrolling, progress in
                    manager.setManualScrolling(scrolling, progress: progress)
                },
                smoothScroll: useSmoothScroll,
                smoothWordProgress: manager.timerWordProgress,
                isListening: manager.service.isListening && !manager.isPaused
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom controls
            HStack(spacing: 12) {
                ElapsedTimeView(fontSize: 11)

                AudioWaveformProgressView(
                    levels: manager.service.audioLevels,
                    progress: manager.words.isEmpty ? 0 : Double(manager.effectiveCharCount) / Double(max(1, manager.words.joined(separator: " ").count))
                )
                .frame(maxWidth: .infinity)
                .frame(height: 28)

                HStack(spacing: 8) {
                    Button(action: { manager.togglePause() }) {
                        Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: { manager.stopTeleprompter() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}
