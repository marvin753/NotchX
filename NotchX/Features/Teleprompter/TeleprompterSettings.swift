//
//  TeleprompterSettings.swift
//  NotchX
//
//  Lightweight wrapper around Defaults teleprompter keys.
//

import AppKit
import Defaults
import SwiftUI

struct TeleprompterSettings {
    static var font: NSFont {
        Defaults[.teleprompterFontFamily].font(size: Defaults[.teleprompterFontSize].pointSize)
    }

    static var highlightColor: Color {
        Defaults[.teleprompterFontColor].color
    }

    static var scrollSpeed: Double {
        Defaults[.teleprompterScrollSpeed]
    }

    static var listeningMode: TeleprompterListeningMode {
        Defaults[.teleprompterListeningMode]
    }
}
