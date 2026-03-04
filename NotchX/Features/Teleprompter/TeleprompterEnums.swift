//
//  TeleprompterEnums.swift
//  NotchX
//
//  Ported from Textream (MIT License) by NotchX contributors.
//

import AppKit
import Defaults
import SwiftUI

// MARK: - Font Size

enum TeleprompterFontSize: String, CaseIterable, Defaults.Serializable {
    case xs = "Extra Small"
    case sm = "Small"
    case lg = "Large"
    case xl = "Extra Large"

    var pointSize: CGFloat {
        switch self {
        case .xs: return 14
        case .sm: return 16
        case .lg: return 20
        case .xl: return 24
        }
    }
}

// MARK: - Font Family

enum TeleprompterFontFamily: String, CaseIterable, Defaults.Serializable {
    case sans = "Sans"
    case serif = "Serif"
    case mono = "Mono"
    case dyslexia = "Dyslexia"

    func font(size: CGFloat, weight: NSFont.Weight = .semibold) -> NSFont {
        switch self {
        case .sans:
            return NSFont.systemFont(ofSize: size, weight: weight)
        case .serif:
            let descriptor = NSFontDescriptor.preferredFontDescriptor(forTextStyle: .body)
                .withDesign(.serif) ?? NSFontDescriptor()
            return NSFont(descriptor: descriptor.withSymbolicTraits(.bold), size: size)
                ?? NSFont.systemFont(ofSize: size, weight: weight)
        case .mono:
            return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        case .dyslexia:
            return NSFont(name: "OpenDyslexic3", size: size)
                ?? NSFont.systemFont(ofSize: size, weight: weight)
        }
    }
}

// MARK: - Font Color

enum TeleprompterFontColor: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case pink = "Pink"
    case orange = "Orange"

    var color: Color {
        switch self {
        case .white: return .white
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return Color(.systemBlue)
        case .pink: return .pink
        case .orange: return .orange
        }
    }

    var label: String { rawValue }
}

// MARK: - Listening Mode

enum TeleprompterListeningMode: String, CaseIterable, Defaults.Serializable {
    case wordTracking = "Word Tracking"
    case classic = "Classic"
    case silencePaused = "Voice-Activated"

    var description: String {
        switch self {
        case .wordTracking:
            return "Highlights words as you speak them"
        case .classic:
            return "Scrolls at a constant speed"
        case .silencePaused:
            return "Scrolls while you speak, pauses on silence"
        }
    }

    var icon: String {
        switch self {
        case .wordTracking: return "text.word.spacing"
        case .classic: return "arrow.down.circle"
        case .silencePaused: return "waveform.circle"
        }
    }
}
