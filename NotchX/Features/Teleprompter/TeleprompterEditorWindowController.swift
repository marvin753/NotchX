//
//  TeleprompterEditorWindowController.swift
//  NotchX
//
//  Standalone editor window for teleprompter script input.
//

import AppKit
import SwiftUI

class TeleprompterEditorWindowController: NSWindowController {
    static let shared = TeleprompterEditorWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        setupWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        guard let window = window else { return }

        window.title = "Teleprompter Editor"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.toolbarStyle = .unified
        window.isMovableByWindowBackground = true

        window.collectionBehavior = [.managed, .participatesInCycle, .fullScreenAuxiliary]

        window.hidesOnDeactivate = false
        window.isExcludedFromWindowsMenu = false

        window.isRestorable = true
        window.identifier = NSUserInterfaceItemIdentifier("TeleprompterEditorWindow")

        let editorView = TeleprompterEditorView()
        let hostingView = NSHostingView(rootView: editorView)
        window.contentView = hostingView

        window.delegate = self
    }

    func showWindow() {
        NSApp.setActivationPolicy(.regular)

        if window?.isVisible == true {
            NSApp.activate(ignoringOtherApps: true)
            window?.orderFrontRegardless()
            window?.makeKeyAndOrderFront(nil)
            return
        }

        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        window?.center()

        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async { [weak self] in
            self?.window?.makeKeyAndOrderFront(nil)
        }
    }

    func hideWindow() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    override func close() {
        super.close()
        relinquishFocus()
    }

    private func relinquishFocus() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }
}

extension TeleprompterEditorWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        relinquishFocus()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    func windowDidBecomeKey(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func windowDidResignKey(_ notification: Notification) {
    }
}
