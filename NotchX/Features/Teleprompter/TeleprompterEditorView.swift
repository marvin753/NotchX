//
//  TeleprompterEditorView.swift
//  NotchX
//
//  SwiftUI content for the teleprompter editor window.
//

import Defaults
import SwiftUI

struct TeleprompterEditorView: View {
    @ObservedObject private var manager = TeleprompterManager.shared
    @Default(.teleprompterListeningMode) private var listeningMode

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $manager.scriptText)
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if manager.scriptText.isEmpty {
                        Text("Paste or type your script here...")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(.horizontal, 5)
                            .allowsHitTesting(false)
                    }
                }
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if let error = manager.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Divider()
                .padding(.top, 12)

            HStack(spacing: 12) {
                Picker("Mode", selection: $listeningMode) {
                    ForEach(TeleprompterListeningMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(manager.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(manager.isActive ? "Active" : "Idle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if manager.isActive {
                    Button(action: { manager.stopTeleprompter() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { manager.startTeleprompter() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(manager.scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

#Preview("Teleprompter Editor") {
    TeleprompterEditorView()
        .frame(width: 600, height: 400)
        .padding()
}

