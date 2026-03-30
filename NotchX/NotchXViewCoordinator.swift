//
//  NotchXViewCoordinator.swift
//  NotchX
//
//  Created by Alexander on 2024-11-20.
//

import AppKit
import Combine
import Defaults
import SwiftUI

enum SneakContentType {
    case brightness
    case volume
    case backlight
    case music
    case mic
    case battery
    case download
}

struct sneakPeek {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var icon: String = ""
}

struct SharedSneakPeek: Codable {
    var show: Bool
    var type: String
    var value: String
    var icon: String
}

enum BrowserType {
    case chromium
    case safari
}

enum PreferredDisplayTarget: String, CaseIterable, Hashable {
    case builtin
    case external
}

struct ExpandedItem {
    var show: Bool = false
    var type: SneakContentType = .battery
    var value: CGFloat = 0
    var browser: BrowserType = .chromium
}

@MainActor
class NotchXViewCoordinator: ObservableObject {
    static let shared = NotchXViewCoordinator()

    @Published var currentView: NotchViews = .home
    @Published var helloAnimationRunning: Bool = false
    private var sneakPeekDispatch: DispatchWorkItem?
    private var expandingViewDispatch: DispatchWorkItem?
    private var hudEnableTask: Task<Void, Never>?

    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @AppStorage("showWhatsNew") var showWhatsNew: Bool = true
    @AppStorage("musicLiveActivityEnabled") var musicLiveActivityEnabled: Bool = true
    @AppStorage("currentMicStatus") var currentMicStatus: Bool = true

    @AppStorage("alwaysShowTabs") var alwaysShowTabs: Bool = true {
        didSet {
            if !alwaysShowTabs {
                openLastTabByDefault = false
                if ShelfStateViewModel.shared.isEmpty || !Defaults[.openShelfByDefault] {
                    currentView = .home
                }
            }
        }
    }

    @AppStorage("openLastTabByDefault") var openLastTabByDefault: Bool = false {
        didSet {
            if openLastTabByDefault {
                alwaysShowTabs = true
            }
        }
    }
    
    @Default(.hudReplacement) var hudReplacement: Bool
    @Default(.teleprompterEnabled) var teleprompterEnabled: Bool
    
    // Legacy storage for migration
    @AppStorage("preferred_screen_name") private var legacyPreferredScreenName: String?

    // UUID- and target-based storage
    @AppStorage("preferred_screen_uuid") private var storedPreferredScreenUUID: String?
    @AppStorage("preferred_display_target") private var storedPreferredDisplayTargetRaw: String?
    @AppStorage("preferred_external_screen_uuid") private var storedPreferredExternalScreenUUID: String?

    var preferredScreenUUID: String? { storedPreferredScreenUUID }

    var preferredDisplayTarget: PreferredDisplayTarget {
        PreferredDisplayTarget(rawValue: storedPreferredDisplayTargetRaw ?? "") ?? defaultPreferredDisplayTarget()
    }

    var preferredExternalScreenUUID: String? { storedPreferredExternalScreenUUID }

    @Published var selectedScreenUUID: String = NSScreen.main?.displayUUID ?? ""

    @Published var optionKeyPressed: Bool = true
    private var accessibilityObserver: Any?
    private var hudReplacementCancellable: AnyCancellable?
    private var teleprompterEnabledCancellable: AnyCancellable?

    private init() {
        migrateLegacyPreferredDisplayIfNeeded()
        ensurePreferredDisplayDefaults()
        normalizePreferredDisplaySelection(postNotification: false)
        // Observe changes to accessibility authorization and react accordingly
        accessibilityObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.accessibilityAuthorizationChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if Defaults[.hudReplacement] {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }

        // Observe changes to hudReplacement
        hudReplacementCancellable = Defaults.publisher(.hudReplacement)
            .sink { [weak self] change in
                Task { @MainActor in
                    guard let self = self else { return }

                    // #region agent log
                    _nxDbg("hudReplacement publisher fired", ["oldValue": change.oldValue, "newValue": change.newValue, "hudEnableTaskExists": self.hudEnableTask != nil], h: "B", loc: "NotchXViewCoordinator.swift:hudReplacement-sink")
                    // #endregion

                    self.hudEnableTask?.cancel()
                    self.hudEnableTask = nil

                    if change.newValue {
                        self.hudEnableTask = Task { @MainActor in
                            let granted = await XPCHelperClient.shared.ensureAccessibilityAuthorization(promptIfNeeded: true)
                            // #region agent log
                            _nxDbg("hudEnableTask: after ensureAuth", ["granted": granted, "isCancelled": Task.isCancelled], h: "B", loc: "NotchXViewCoordinator.swift:hudEnableTask-afterAuth")
                            // #endregion
                            if Task.isCancelled {
                                // #region agent log
                                _nxDbg("hudEnableTask: CANCELLED before start()", h: "B", loc: "NotchXViewCoordinator.swift:hudEnableTask-cancelled")
                                // #endregion
                                return
                            }

                            if granted {
                                await MediaKeyInterceptor.shared.start()
                            } else {
                                Defaults[.hudReplacement] = false
                            }
                        }
                    } else {
                        MediaKeyInterceptor.shared.stop()
                    }
                }
            }

        // Observe teleprompter enabled: switch away if disabled while on teleprompter tab
        teleprompterEnabledCancellable = Defaults.publisher(.teleprompterEnabled)
            .sink { [weak self] change in
                Task { @MainActor in
                    guard let self else { return }
                    if !change.newValue && self.currentView == .teleprompter {
                        self.currentView = .home
                    }
                }
            }


        Task { @MainActor in
            helloAnimationRunning = firstLaunch

            // #region agent log
            _nxDbg("init startup Task", ["hudReplacement": Defaults[.hudReplacement]], h: "ALL", loc: "NotchXViewCoordinator.swift:init-startup")
            // #endregion

            if Defaults[.hudReplacement] {
                let authorized = await XPCHelperClient.shared.isAccessibilityAuthorized()
                // #region agent log
                _nxDbg("init startup: accessibility result", ["authorized": authorized], h: "ALL", loc: "NotchXViewCoordinator.swift:init-startup-auth")
                // #endregion
                if !authorized {
                    Defaults[.hudReplacement] = false
                } else {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }
    }

    func setPreferredDisplayTarget(
        _ target: PreferredDisplayTarget,
        postNotification: Bool = true
    ) {
        storedPreferredDisplayTargetRaw = target.rawValue
        normalizePreferredDisplaySelection(postNotification: postNotification)
    }

    func setPreferredExternalScreenUUID(
        _ uuid: String?,
        postNotification: Bool = true
    ) {
        storedPreferredDisplayTargetRaw = PreferredDisplayTarget.external.rawValue
        storedPreferredExternalScreenUUID = uuid
        normalizePreferredDisplaySelection(postNotification: postNotification)
    }

    func setPreferredFallbackScreenUUID(
        _ uuid: String?,
        postNotification: Bool = true
    ) {
        storedPreferredScreenUUID = uuid

        if let uuid, let screen = NSScreen.screen(withUUID: uuid) {
            storedPreferredDisplayTargetRaw = screen.isBuiltIn
                ? PreferredDisplayTarget.builtin.rawValue
                : PreferredDisplayTarget.external.rawValue

            if !screen.isBuiltIn {
                storedPreferredExternalScreenUUID = uuid
            }
        }

        normalizePreferredDisplaySelection(postNotification: postNotification)
    }

    func normalizePreferredDisplaySelection(postNotification: Bool = true) {
        let previousPreferredScreenUUID = storedPreferredScreenUUID
        let previousSelectedScreenUUID = selectedScreenUUID

        let screens = NSScreen.screens
        let builtInScreen = screens.first(where: \.isBuiltIn)
        let externalScreens = screens.filter { !$0.isBuiltIn }

        let resolvedTarget: PreferredDisplayTarget
        let resolvedUUID: String?

        if let builtInScreen {
            switch preferredDisplayTarget {
            case .builtin:
                resolvedTarget = .builtin
                resolvedUUID = builtInScreen.displayUUID ?? firstAvailableScreenUUID(in: screens)
            case .external:
                if externalScreens.isEmpty {
                    resolvedTarget = .builtin
                    resolvedUUID = builtInScreen.displayUUID ?? firstAvailableScreenUUID(in: screens)
                } else {
                    resolvedTarget = .external
                    resolvedUUID = resolveExternalScreenUUID(from: externalScreens)
                }
            }
        } else {
            resolvedTarget = preferredDisplayTarget
            resolvedUUID = resolveFallbackScreenUUID(in: screens)
        }

        storedPreferredDisplayTargetRaw = resolvedTarget.rawValue
        storedPreferredScreenUUID = resolvedUUID

        if let resolvedUUID {
            selectedScreenUUID = resolvedUUID

            if let resolvedScreen = NSScreen.screen(withUUID: resolvedUUID),
               !resolvedScreen.isBuiltIn {
                storedPreferredExternalScreenUUID = resolvedUUID
            }
        } else {
            selectedScreenUUID = ""
        }

        if postNotification,
           previousPreferredScreenUUID != storedPreferredScreenUUID
            || previousSelectedScreenUUID != selectedScreenUUID {
            NotificationCenter.default.post(name: Notification.Name.selectedScreenChanged, object: nil)
        }
    }

    private func migrateLegacyPreferredDisplayIfNeeded() {
        guard storedPreferredScreenUUID == nil, let legacyName = legacyPreferredScreenName else {
            return
        }

        if let screen = NSScreen.screens.first(where: { $0.localizedName == legacyName }),
           let uuid = screen.displayUUID {
            storedPreferredScreenUUID = uuid
            storedPreferredDisplayTargetRaw = screen.isBuiltIn
                ? PreferredDisplayTarget.builtin.rawValue
                : PreferredDisplayTarget.external.rawValue

            if !screen.isBuiltIn {
                storedPreferredExternalScreenUUID = uuid
            }

            NSLog("✅ Migrated display preference from name '\(legacyName)' to UUID '\(uuid)'")
        } else {
            storedPreferredScreenUUID = NSScreen.main?.displayUUID ?? firstAvailableScreenUUID(in: NSScreen.screens)
            storedPreferredDisplayTargetRaw = defaultPreferredDisplayTarget().rawValue
            NSLog("⚠️ Could not find display named '\(legacyName)', falling back to the active screen")
        }

        legacyPreferredScreenName = nil
    }

    private func ensurePreferredDisplayDefaults() {
        if storedPreferredScreenUUID == nil {
            if let builtInUUID = NSScreen.builtInScreen?.displayUUID {
                storedPreferredScreenUUID = builtInUUID
            } else {
                storedPreferredScreenUUID = NSScreen.main?.displayUUID ?? firstAvailableScreenUUID(in: NSScreen.screens)
            }
        }

        if storedPreferredDisplayTargetRaw == nil {
            if let preferredScreenUUID = storedPreferredScreenUUID,
               let preferredScreen = NSScreen.screen(withUUID: preferredScreenUUID) {
                storedPreferredDisplayTargetRaw = preferredScreen.isBuiltIn
                    ? PreferredDisplayTarget.builtin.rawValue
                    : PreferredDisplayTarget.external.rawValue
            } else {
                storedPreferredDisplayTargetRaw = defaultPreferredDisplayTarget().rawValue
            }
        }

        if storedPreferredExternalScreenUUID == nil,
           let preferredScreenUUID = storedPreferredScreenUUID,
           let preferredScreen = NSScreen.screen(withUUID: preferredScreenUUID),
           !preferredScreen.isBuiltIn {
            storedPreferredExternalScreenUUID = preferredScreenUUID
        }
    }

    private func defaultPreferredDisplayTarget() -> PreferredDisplayTarget {
        NSScreen.builtInScreen == nil ? .external : .builtin
    }

    private func firstAvailableScreenUUID(in screens: [NSScreen]) -> String? {
        screens.compactMap(\.displayUUID).first
    }

    private func resolveExternalScreenUUID(from externalScreens: [NSScreen]) -> String? {
        let externalUUIDs = externalScreens.compactMap(\.displayUUID)

        if externalUUIDs.count == 1 {
            return externalUUIDs.first
        }

        if let rememberedExternalUUID = storedPreferredExternalScreenUUID,
           externalUUIDs.contains(rememberedExternalUUID) {
            return rememberedExternalUUID
        }

        if let currentPreferredUUID = storedPreferredScreenUUID,
           externalUUIDs.contains(currentPreferredUUID) {
            return currentPreferredUUID
        }

        return externalUUIDs.first
    }

    private func resolveFallbackScreenUUID(in screens: [NSScreen]) -> String? {
        let availableUUIDs = Set(screens.compactMap(\.displayUUID))

        if let preferredScreenUUID = storedPreferredScreenUUID,
           availableUUIDs.contains(preferredScreenUUID) {
            return preferredScreenUUID
        }

        if let preferredExternalScreenUUID = storedPreferredExternalScreenUUID,
           availableUUIDs.contains(preferredExternalScreenUUID) {
            return preferredExternalScreenUUID
        }

        if availableUUIDs.contains(selectedScreenUUID) {
            return selectedScreenUUID
        }

        return NSScreen.main?.displayUUID ?? firstAvailableScreenUUID(in: screens)
    }
    
    @objc func sneakPeekEvent(_ notification: Notification) {
        guard
            let payload = (notification.userInfo?.values.compactMap { $0 as? Data }.first)
                ?? (notification.object as? Data)
        else {
            print("Failed to decode JSON data: missing payload")
            return
        }

        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(SharedSneakPeek.self, from: payload) {
            let contentType =
                decodedData.type == "brightness"
                ? SneakContentType.brightness
                : decodedData.type == "volume"
                    ? SneakContentType.volume
                    : decodedData.type == "backlight"
                        ? SneakContentType.backlight
                        : decodedData.type == "mic"
                            ? SneakContentType.mic : SneakContentType.brightness

            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.numberStyle = .decimal
            let value = CGFloat((formatter.number(from: decodedData.value) ?? 0.0).floatValue)
            let icon = decodedData.icon

            print("Decoded: \(decodedData), Parsed value: \(value)")

            toggleSneakPeek(status: decodedData.show, type: contentType, value: value, icon: icon)

        } else {
            print("Failed to decode JSON data")
        }
    }

    func toggleSneakPeek(
        status: Bool, type: SneakContentType, duration: TimeInterval = 1.5, value: CGFloat = 0,
        icon: String = ""
    ) {
        sneakPeekDuration = duration
        if type != .music {
            // close()
            if !Defaults[.hudReplacement] {
                // #region agent log
                _nxDbg("toggleSneakPeek BLOCKED: hudReplacement is false", ["type": "\(type)", "status": status, "value": value], h: "C", loc: "NotchXViewCoordinator.swift:toggleSneakPeek-blocked")
                // #endregion
                return
            }
        }
        // #region agent log
        _nxDbg("toggleSneakPeek executing", ["type": "\(type)", "status": status, "value": value], h: "ALL", loc: "NotchXViewCoordinator.swift:toggleSneakPeek-exec")
        // #endregion
        Task { @MainActor in
            withAnimation(.smooth) {
                self.sneakPeek.show = status
                self.sneakPeek.type = type
                self.sneakPeek.value = value
                self.sneakPeek.icon = icon
            }
        }

        if type == .mic {
            currentMicStatus = value == 1
        }
    }

    private var sneakPeekDuration: TimeInterval = 1.5
    private var sneakPeekTask: Task<Void, Never>?

    // Helper function to manage sneakPeek timer using Swift Concurrency
    private func scheduleSneakPeekHide(after duration: TimeInterval) {
        sneakPeekTask?.cancel()

        sneakPeekTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self = self, !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    self.toggleSneakPeek(status: false, type: .music)
                    self.sneakPeekDuration = 1.5
                }
            }
        }
    }

    @Published var sneakPeek: sneakPeek = .init() {
        didSet {
            if sneakPeek.show {
                scheduleSneakPeekHide(after: sneakPeekDuration)
            } else {
                sneakPeekTask?.cancel()
            }
        }
    }

    func toggleExpandingView(
        status: Bool,
        type: SneakContentType,
        value: CGFloat = 0,
        browser: BrowserType = .chromium
    ) {
        Task { @MainActor in
            withAnimation(.smooth) {
                self.expandingView.show = status
                self.expandingView.type = type
                self.expandingView.value = value
                self.expandingView.browser = browser
            }
        }
    }

    private var expandingViewTask: Task<Void, Never>?

    @Published var expandingView: ExpandedItem = .init() {
        didSet {
            if expandingView.show {
                expandingViewTask?.cancel()
                let duration: TimeInterval = (expandingView.type == .download ? 2 : 3)
                let currentType = expandingView.type
                expandingViewTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(duration))
                    guard let self = self, !Task.isCancelled else { return }
                    self.toggleExpandingView(status: false, type: currentType)
                }
            } else {
                expandingViewTask?.cancel()
            }
        }
    }
    
    func showEmpty() {
        currentView = .home
    }
}
