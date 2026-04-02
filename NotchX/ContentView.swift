//
//  ContentView.swift
//  NotchXApp
//
//  Created by Harsh Vardhan Goswami  on 02/08/24
//  Modified by Richard Kunkli on 24/08/2024.
//

import AVFoundation
import Combine
import Defaults
import Foundation
import KeyboardShortcuts
import SwiftUI
import SwiftUIIntrospect

private enum SwipeDirection {
    case undetermined
    case horizontal
    case vertical
}

private enum SkipSwipePhase {
    case idle
    case dragging(direction: SwipeDirection)
    case committing
    case cancelling
}

private enum SwipeSkipAction {
    case next
    case previous

    var dragSign: CGFloat {
        switch self {
        case .next:
            return 1
        case .previous:
            return -1
        }
    }
}

private struct SwipeVelocitySample {
    let translation: CGFloat
    let timestamp: Date
}

private struct TrackSignature: Equatable {
    let title: String
    let artist: String
    let album: String
    let bundleIdentifier: String?
}

private struct HorizontalSwipeScrollMonitor: NSViewRepresentable {
    let onChanged: (CGFloat, CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.installMonitor(on: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    @MainActor final class Coordinator: NSObject {
        private let onChanged: (CGFloat, CGFloat) -> Void
        private let onEnded: (CGFloat) -> Void
        private var monitor: Any?
        private var accumulatedX: CGFloat = 0
        private var accumulatedY: CGFloat = 0
        private var active = false
        private var isPreciseGesture = false
        private var endTask: Task<Void, Never>?
        private let activationThreshold: CGFloat = 5

        init(onChanged: @escaping (CGFloat, CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func installMonitor(on view: NSView) {
            removeMonitor()
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self, weak view] event in
                guard let self, event.window === view?.window else { return event }
                self.handleScroll(event)
                return event
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            resetState()
        }

        private func scheduleEndTimeout(timeoutMs: Int) {
            endTask?.cancel()
            endTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(timeoutMs))
                guard !Task.isCancelled else { return }
                if active {
                    onEnded(accumulatedX)
                }
                resetState()
            }
        }

        private func resetState() {
            active = false
            isPreciseGesture = false
            accumulatedX = 0
            accumulatedY = 0
            endTask?.cancel()
        }

        private func handleScroll(_ event: NSEvent) {
            // Ignore momentum (inertia after fingers lift)
            guard event.momentumPhase == [] else { return }

            // New gesture starting — clean up any stale state from a missed .ended
            if event.phase == .began {
                if active {
                    onEnded(0)  // pass 0 to cancel without committing a stale swipe
                }
                resetState()
                isPreciseGesture = event.hasPreciseScrollingDeltas
                return
            }

            if event.phase == .ended || event.phase == .cancelled {
                if active {
                    onEnded(accumulatedX)
                }
                resetState()
                return
            }

            let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 8
            let deltaX = event.scrollingDeltaX * scale
            let deltaY = event.scrollingDeltaY * scale

            let absDX = abs(deltaX)
            let absDY = abs(deltaY)
            let axisDominanceFactor: CGFloat = 1.5
            guard absDX >= absDY * axisDominanceFactor || (active && absDX > 0.2) else { return }

            accumulatedX += deltaX
            accumulatedY += deltaY

            if !active {
                guard abs(accumulatedX) >= activationThreshold else { return }
                active = true
            }

            onChanged(accumulatedX, accumulatedY)

            // Only use timeout fallback for non-precise devices (mouse wheel)
            if !isPreciseGesture {
                scheduleEndTimeout(timeoutMs: 300)
            }
        }
    }
}

@MainActor
struct ContentView: View {
    @EnvironmentObject var vm: NotchXViewModel
    @ObservedObject var webcamManager = WebcamManager.shared

    @ObservedObject var coordinator = NotchXViewCoordinator.shared
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var brightnessManager = BrightnessManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    @State private var isHoveringClosedMusicCover: Bool = false
    @State private var isHoveringWaves: Bool = false
    @State private var closedHoverScale: CGFloat = 1.0
    @State private var pendingOpenTask: Task<Void, Never>?
    @State private var notchTransitionTask: Task<Void, Never>?
    @State private var isNotchTransitioning: Bool = false
    @State private var anyDropDebounceTask: Task<Void, Never>?
    @State private var isNotchLocked: Bool = false

    @State private var swipePhase: SkipSwipePhase = .idle
    @State private var swipeOffset: CGFloat = 0
    @State private var rawTranslation: CGFloat = 0
    @State private var hasTriggeredThresholdHaptic: Bool = false
    @State private var isDirectionLocked: Bool = false
    @State private var lockedDirection: SwipeDirection = .undetermined
    @State private var arrowOpacity: CGFloat = 0
    @State private var arrowScale: CGFloat = 1.0
    @State private var contentOpacity: CGFloat = 1.0
    @State private var lastSuccessfulSwipeAt: Date = .distantPast
    @State private var lastVelocitySample: SwipeVelocitySample?
    @State private var swipeVelocity: CGFloat = 0
    @State private var swipeShakeOffset: CGFloat = 0
    @State private var blankNotchFlashOpacity: CGFloat = 0
    @State private var swipeExpandAmount: CGFloat = 0
    @State private var swipeCommitTask: Task<Void, Never>?

    @State private var gestureProgress: CGFloat = .zero

    @State private var haptics: Bool = false

    @Namespace var albumArtNamespace

    @Default(.useMusicVisualizer) var useMusicVisualizer

    @Default(.showNotHumanFace) var showNotHumanFace

    // Shared interactive spring for movement/resizing to avoid conflicting animations
    private let animationSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)
    private let closedHoverAnimation = Animation.smooth(duration: 0.3)

    private let extendedHoverPadding: CGFloat = 30
    private let zeroHeightHoverPadding: CGFloat = 10
    private let swipeDirectionLockDistance: CGFloat = 10
    private let swipeDirectionDominanceFactor: CGFloat = 1.5
    private let swipeCancelZone: CGFloat = 15
    private let swipeFlickMinimumDistance: CGFloat = 20
    private let swipeVelocityThreshold: CGFloat = 300
    private let swipeDebounceSeconds: TimeInterval = 0.5
    private let swipeTrackChangeTimeoutSeconds: TimeInterval = 0.3

    private var topCornerRadius: CGFloat {
       ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                ? cornerRadiusInsets.opened.top
                : cornerRadiusInsets.closed.top
    }

    private var isClosedMusicLiveActivityVisible: Bool {
        (!coordinator.expandingView.show || coordinator.expandingView.type == .music)
            && vm.notchState == .closed
            && (musicManager.isPlaying || !musicManager.isPlayerIdle)
            && coordinator.musicLiveActivityEnabled
            && !vm.hideOnClosed
    }

    private var closedMusicNowPlayingText: String {
        let song = musicManager.songTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = musicManager.artistName.trimmingCharacters(in: .whitespacesAndNewlines)

        if song.isEmpty { return artist }
        if artist.isEmpty { return song }
        return "\(song) — \(artist)"
    }

    private var shouldShowClosedMusicHoverMarquee: Bool {
        isClosedMusicLiveActivityVisible
            && isHoveringClosedMusicCover
            && !closedMusicNowPlayingText.isEmpty
    }

    private var closedBottomCornerRadius: CGFloat {
        shouldShowClosedMusicHoverMarquee
            ? max(cornerRadiusInsets.closed.bottom, 22)
            : cornerRadiusInsets.closed.bottom
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                ? cornerRadiusInsets.opened.bottom
                : closedBottomCornerRadius
        )
    }

    private var computedChinWidth: CGFloat {
        var chinWidth: CGFloat = vm.closedNotchSize.width

        if coordinator.expandingView.type == .bluetooth && coordinator.expandingView.show
            && vm.notchState == .closed && Defaults[.showBluetoothNotifications]
        {
            chinWidth = 640
        } else if coordinator.expandingView.type == .battery && coordinator.expandingView.show
            && vm.notchState == .closed && Defaults[.showPowerStatusNotifications]
        {
            chinWidth = 640
        } else if isClosedMusicLiveActivityVisible {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        } else if !coordinator.expandingView.show && vm.notchState == .closed
            && (!musicManager.isPlaying && musicManager.isPlayerIdle) && Defaults[.showNotHumanFace]
            && !vm.hideOnClosed
        {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        }

        return chinWidth
    }

    private var effectiveClosedHoverScale: CGFloat {
        vm.notchState == .closed && !isNotchTransitioning ? closedHoverScale : 1.0
    }

    private var reduceMotionEnabled: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var swipeSkipThreshold: CGFloat {
        Defaults[.swipeSensitivity].skipThreshold
    }

    private var swipeVisualMaxOffset: CGFloat {
        reduceMotionEnabled ? 20 : 60
    }

    private var isSwipeMediaSessionActive: Bool {
        musicManager.isPlaying || !musicManager.isPlayerIdle
    }

    private var isSwipeDebounced: Bool {
        Date().timeIntervalSince(lastSuccessfulSwipeAt) < swipeDebounceSeconds
    }

    private var isBlankNotchSwipeMode: Bool {
        vm.notchState == .closed && isSwipeMediaSessionActive && !coordinator.musicLiveActivityEnabled
    }

    private var shouldSuppressClosedHoverFromSwipe: Bool {
        vm.notchState == .closed && isDirectionLocked && lockedDirection == .horizontal
    }

    private let swipeExpandMaxWidth: CGFloat = 26

    private var swipeExpandEdgeOffset: CGFloat {
        guard vm.notchState == .closed, swipeExpandAmount > 0 else { return 0 }
        return rawTranslation > 0 ? swipeExpandAmount / 2 : -swipeExpandAmount / 2
    }

    private var swipeContentOffset: CGFloat {
        guard vm.notchState == .closed else { return 0 }
        if isBlankNotchSwipeMode {
            return swipeShakeOffset
        }
        return swipeOffset + swipeShakeOffset
    }

    private var swipeContentOpacity: CGFloat {
        guard vm.notchState == .closed else { return 1 }
        if isBlankNotchSwipeMode {
            return 1
        }
        return contentOpacity
    }

    var body: some View {
        // Calculate scale based on gesture progress only
        let gestureScale: CGFloat = {
            guard gestureProgress != 0 else { return 1.0 }
            let scaleFactor = 1.0 + gestureProgress * 0.01
            return max(0.6, scaleFactor)
        }()
        let combinedScale = gestureScale * effectiveClosedHoverScale
        
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                let closedBasePad = cornerRadiusInsets.closed.bottom
                let swipeLeadingExtra: CGFloat = (vm.notchState == .closed && rawTranslation < 0) ? swipeExpandAmount : 0
                let swipeTrailingExtra: CGFloat = (vm.notchState == .closed && rawTranslation > 0) ? swipeExpandAmount : 0

                let mainLayout = NotchLayout()
                    .frame(alignment: .top)
                    .padding(
                        .leading,
                        vm.notchState == .open
                        ? Defaults[.cornerRadiusScaling]
                        ? (cornerRadiusInsets.opened.top) : (cornerRadiusInsets.opened.bottom)
                        : closedBasePad + swipeLeadingExtra
                    )
                    .padding(
                        .trailing,
                        vm.notchState == .open
                        ? Defaults[.cornerRadiusScaling]
                        ? (cornerRadiusInsets.opened.top) : (cornerRadiusInsets.opened.bottom)
                        : closedBasePad + swipeTrailingExtra
                    )
                    .padding([.horizontal, .bottom], vm.notchState == .open ? 12 : 0)
                    .overlay { swipeFeedbackOverlay }
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if vm.notchState == .open {
                            NotchLockButton(isLocked: $isNotchLocked)
                                .transition(.opacity)
                        }
                    }
                    .shadow(
                        color: ((vm.notchState == .open || isHovering) && Defaults[.enableShadow])
                            ? .black.opacity(0.7) : .clear, radius: Defaults[.cornerRadiusScaling] ? 6 : 4
                    )
                    .padding(
                        .bottom,
                        vm.effectiveClosedNotchHeight == 0 ? 10 : 0
                    )
                
                mainLayout
                    .frame(height: vm.notchState == .open ? vm.notchSize.height : nil)
                    .padding(.horizontal, vm.notchState == .open ? shadowPadding / 2 : 0)
                    .frame(
                        maxWidth: vm.notchState == .open
                            ? .infinity
                            : computedChinWidth + extendedHoverPadding * 2 + swipeExpandAmount,
                        alignment: .center
                    )
                    .offset(x: swipeExpandEdgeOffset)
                    .conditionalModifier(true) { view in
                        let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
                        let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)
                        
                        return view
                            .animation(vm.notchState == .open ? openAnimation : closeAnimation, value: vm.notchState)
                            .animation(.smooth, value: gestureProgress)
                    }
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        doOpen()
                    }
                    .panGesture(direction: .down) { translation, phase in
                        handleDownGesture(translation: translation, phase: phase)
                    }
                    .conditionalModifier(Defaults[.closeGestureEnabled]) { view in
                        view
                            .panGesture(direction: .up) { translation, phase in
                                handleUpGesture(translation: translation, phase: phase)
                            }
                    }
                    .simultaneousGesture(horizontalSwipeGesture)
                    .background(
                        HorizontalSwipeScrollMonitor(
                            onChanged: { translationX, translationY in
                                processSwipeChanged(translationX: translationX, translationY: translationY)
                            },
                            onEnded: { translationX in
                                processSwipeEnded(translationX: translationX, velocity: swipeVelocity)
                            }
                        )
                        .frame(width: 0, height: 0)
                    )
                    .onReceive(NotificationCenter.default.publisher(for: .sharingDidFinish)) { _ in
                        if vm.notchState == .open && !isHovering && !vm.isBatteryPopoverActive && !vm.isBluetoothPopoverActive && !isNotchLocked {
                            hoverTask?.cancel()
                            hoverTask = Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    if self.vm.notchState == .open && !self.isHovering && !self.vm.isBatteryPopoverActive && !self.vm.isBluetoothPopoverActive && !SharingStateManager.shared.preventNotchClose && !self.isNotchLocked {
                                        self.closeNotch()
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: vm.notchState) { _, newState in
                        scheduleNotchTransitionWindow(for: newState)
                        resetClosedHoverScaleImmediately()
                        resetSwipeState()

                        if newState == .closed {
                            isNotchLocked = false
                        }
                        if newState == .closed && isHovering {
                            withAnimation {
                                isHovering = false
                            }
                        }
                        if newState != .closed {
                            withAnimation(.smooth(duration: 0.15)) {
                                isHoveringClosedMusicCover = false
                            }
                        }
                    }
                    .onChange(of: isClosedMusicLiveActivityVisible) { _, isVisible in
                        if !isVisible && isHoveringClosedMusicCover {
                            withAnimation(.smooth(duration: 0.15)) {
                                isHoveringClosedMusicCover = false
                            }
                        }
                        if !isVisible && isHoveringWaves {
                            withAnimation(.smooth(duration: 0.15)) {
                                isHoveringWaves = false
                            }
                        }
                    }
                    .onChange(of: vm.isBatteryPopoverActive) {
                        if !vm.isBatteryPopoverActive && !isHovering && vm.notchState == .open && !SharingStateManager.shared.preventNotchClose && !isNotchLocked {
                            hoverTask?.cancel()
                            hoverTask = Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    if !self.vm.isBatteryPopoverActive && !self.isHovering && self.vm.notchState == .open && !SharingStateManager.shared.preventNotchClose && !self.isNotchLocked {
                                        self.closeNotch()
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: vm.isBluetoothPopoverActive) {
                        if !vm.isBluetoothPopoverActive && !isHovering && vm.notchState == .open && !SharingStateManager.shared.preventNotchClose && !isNotchLocked {
                            hoverTask?.cancel()
                            hoverTask = Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    if !self.vm.isBluetoothPopoverActive && !self.isHovering && self.vm.notchState == .open && !SharingStateManager.shared.preventNotchClose && !self.isNotchLocked {
                                        self.closeNotch()
                                    }
                                }
                            }
                        }
                    }
                    .sensoryFeedback(.alignment, trigger: haptics)
                    .contextMenu {
                        Button("Settings") {
                            SettingsWindowController.shared.showWindow()
                        }
                        .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                        //                    Button("Edit") { // Doesnt work....
                        //                        let dn = DynamicNotch(content: EditPanelView())
                        //                        dn.toggle()
                        //                    }
                        //                    .keyboardShortcut("E", modifiers: .command)
                    }
                if vm.chinHeight > 0 {
                    Rectangle()
                        .fill(Color.black.opacity(0.01))
                        .frame(width: computedChinWidth, height: vm.chinHeight)
                }
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: windowSize.width, maxHeight: windowSize.height, alignment: .top)
        .compositingGroup()
        .scaleEffect(
            x: combinedScale,
            y: combinedScale,
            anchor: .top
        )
        .animation(.smooth, value: gestureProgress)
        .background(dragDetector)
        .preferredColorScheme(.dark)
        .environmentObject(vm)
        .onChange(of: vm.anyDropZoneTargeting) { _, isTargeted in
            anyDropDebounceTask?.cancel()

            if isTargeted {
                if vm.notchState == .closed {
                    coordinator.currentView = .shelf
                    doOpen()
                }
                return
            }

            anyDropDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                if vm.dropEvent {
                    vm.dropEvent = false
                    return
                }

                vm.dropEvent = false
                if !SharingStateManager.shared.preventNotchClose && !isNotchLocked {
                    closeNotch()
                }
            }
        }
        .onDisappear {
            pendingOpenTask?.cancel()
            notchTransitionTask?.cancel()
        }
    }

    @ViewBuilder
    func NotchLayout() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                if coordinator.helloAnimationRunning {
                    Spacer()
                    HelloAnimation(onFinish: {
                        vm.closeHello()
                    }).frame(
                        width: getClosedNotchSize().width,
                        height: 80
                    )
                    .padding(.top, 40)
                    Spacer()
                } else {
                    if coordinator.expandingView.type == .bluetooth && coordinator.expandingView.show
                        && vm.notchState == .closed && Defaults[.showBluetoothNotifications]
                    {
                        BluetoothConnectionNotification()
                    } else if coordinator.expandingView.type == .battery && coordinator.expandingView.show
                        && vm.notchState == .closed && Defaults[.showPowerStatusNotifications]
                    {
                        HStack(spacing: 0) {
                            HStack {
                                Text(batteryModel.statusText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }

                            Rectangle()
                                .fill(.black)
                                .frame(width: vm.closedNotchSize.width + 10)

                            HStack {
                                NotchXBatteryView(
                                    batteryWidth: 30,
                                    isCharging: batteryModel.isCharging,
                                    isInLowPowerMode: batteryModel.isInLowPowerMode,
                                    isPluggedIn: batteryModel.isPluggedIn,
                                    levelBattery: batteryModel.levelBattery,
                                    isForNotification: true
                                )
                            }
                            .frame(width: 76, alignment: .trailing)
                        }
                        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
                      } else if coordinator.sneakPeek.show && Defaults[.inlineHUD] && (coordinator.sneakPeek.type != .music) && (coordinator.sneakPeek.type != .battery) && vm.notchState == .closed {
                          InlineHUD(type: $coordinator.sneakPeek.type, value: $coordinator.sneakPeek.value, icon: $coordinator.sneakPeek.icon, hoverAnimation: $isHovering, gestureProgress: $gestureProgress)
                              .transition(.opacity)
                      } else if isClosedMusicLiveActivityVisible {
                          MusicLiveActivity()
                              .frame(alignment: .center)
                      } else if !coordinator.expandingView.show && vm.notchState == .closed && (!musicManager.isPlaying && musicManager.isPlayerIdle) && Defaults[.showNotHumanFace] && !vm.hideOnClosed  {
                          NotchXFaceAnimation()
                       } else if vm.notchState == .open {
                           NotchXHeader()
                               .frame(height: max(24, vm.effectiveClosedNotchHeight))
                               .opacity(gestureProgress != 0 ? 1.0 - min(abs(gestureProgress) * 0.1, 0.3) : 1.0)
                       } else {
                           Rectangle().fill(.clear).frame(width: vm.closedNotchSize.width - 20, height: vm.effectiveClosedNotchHeight)
                       }

                      if shouldShowClosedMusicHoverMarquee {
                          GeometryReader { geo in
                              MarqueeText(
                                  .constant(closedMusicNowPlayingText),
                                  font: .subheadline,
                                  nsFont: .subheadline,
                                  textColor: Defaults[.playerColorTinting]
                                      ? Color(nsColor: musicManager.avgColor).ensureMinimumBrightness(factor: 0.6)
                                      : .gray,
                                  minDuration: 0.8,
                                  frameWidth: max(0, geo.size.width)
                              )
                          }
                          .frame(height: 16)
                          .padding(.top, 2)
                          .padding(.bottom, 8)
                          .padding(.horizontal, 12)
                          .transition(.opacity)
                          .animation(.smooth(duration: 0.25), value: shouldShowClosedMusicHoverMarquee)
                      }

                      if coordinator.sneakPeek.show {
                          if (coordinator.sneakPeek.type != .music) && (coordinator.sneakPeek.type != .battery) && !Defaults[.inlineHUD] && vm.notchState == .closed {
                              SystemEventIndicatorModifier(
                                  eventType: $coordinator.sneakPeek.type,
                                  value: $coordinator.sneakPeek.value,
                                  icon: $coordinator.sneakPeek.icon,
                                  sendEventBack: { newVal in
                                      switch coordinator.sneakPeek.type {
                                      case .volume:
                                          VolumeManager.shared.setAbsolute(Float32(newVal))
                                      case .brightness:
                                          BrightnessManager.shared.setAbsolute(value: Float32(newVal))
                                      default:
                                          break
                                      }
                                  }
                              )
                              .padding(.bottom, 10)
                              .padding(.leading, 4)
                              .padding(.trailing, 8)
                          }
                          // Old sneak peek music
                          else if coordinator.sneakPeek.type == .music {
                              if vm.notchState == .closed && !vm.hideOnClosed && Defaults[.sneakPeekStyles] == .standard {
                                  HStack(alignment: .center) {
                                      Image(systemName: "music.note")
                                      GeometryReader { geo in
                                          MarqueeText(.constant(musicManager.songTitle + " - " + musicManager.artistName),  textColor: Defaults[.playerColorTinting] ? Color(nsColor: musicManager.avgColor).ensureMinimumBrightness(factor: 0.6) : .gray, minDuration: 1, frameWidth: geo.size.width)
                                      }
                                  }
                                  .foregroundStyle(.gray)
                                  .padding(.bottom, 10)
                              }
                          }
                      }

                  }
              }
              .conditionalModifier((coordinator.sneakPeek.show && (coordinator.sneakPeek.type == .music) && vm.notchState == .closed && !vm.hideOnClosed && Defaults[.sneakPeekStyles] == .standard) || (coordinator.sneakPeek.show && (coordinator.sneakPeek.type != .music) && (vm.notchState == .closed)) || shouldShowClosedMusicHoverMarquee) { view in
                  view
                      .fixedSize()
              }
              .zIndex(2)
            if vm.notchState == .open {
                VStack {
                    switch coordinator.currentView {
                    case .home:
                        NotchHomeView(albumArtNamespace: albumArtNamespace)
                            .transition(.asymmetric(
                                insertion: .offset(y: -30)
                                    .combined(with: .opacity)
                                    .combined(with: .modifier(
                                        active: BlurTransitionModifier(blurRadius: 20),
                                        identity: BlurTransitionModifier(blurRadius: 0)
                                    )),
                                removal: .opacity
                            ))
                    case .shelf:
                        ShelfView()
                            .transition(.asymmetric(
                                insertion: .offset(y: -30)
                                    .combined(with: .opacity)
                                    .combined(with: .modifier(
                                        active: BlurTransitionModifier(blurRadius: 20),
                                        identity: BlurTransitionModifier(blurRadius: 0)
                                    )),
                                removal: .opacity
                            ))
                    case .teleprompter:
                        TeleprompterModule()
                            .transition(.asymmetric(
                                insertion: .offset(y: -30)
                                    .combined(with: .opacity)
                                    .combined(with: .modifier(
                                        active: BlurTransitionModifier(blurRadius: 20),
                                        identity: BlurTransitionModifier(blurRadius: 0)
                                    )),
                                removal: .opacity
                            ))
                    }
                }
                .animation(.smooth(duration: 0.45), value: coordinator.currentView)
                .zIndex(1)
                .allowsHitTesting(vm.notchState == .open)
                .opacity(gestureProgress != 0 ? 1.0 - min(abs(gestureProgress) * 0.1, 0.3) : 1.0)
            }
        }
        .offset(x: swipeContentOffset)
        .opacity(swipeContentOpacity)
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], delegate: GeneralDropTargetDelegate(isTargeted: $vm.generalDropTargeting))
    }

    // MARK: - Swipe to Skip

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                handleHorizontalSwipeChanged(value)
            }
            .onEnded { value in
                handleHorizontalSwipeEnded(value)
            }
    }

    @ViewBuilder
    private var swipeFeedbackOverlay: some View {
        if vm.notchState == .closed {
            ZStack {
                if blankNotchFlashOpacity > 0 {
                    Color.white
                        .opacity(blankNotchFlashOpacity)
                        .blendMode(.screen)
                }

                if swipeExpandAmount > 0, isDirectionLocked, lockedDirection == .horizontal {
                    let progress = min(1, arrowOpacity)
                    let blurRadius: CGFloat = 4 * (1 - progress)

                    HStack(spacing: 0) {
                        if rawTranslation > 0 {
                            Spacer(minLength: 0)
                            swipeSkipIcon
                                .blur(radius: blurRadius)
                                .frame(width: swipeExpandAmount)
                        } else {
                            swipeSkipIcon
                                .blur(radius: blurRadius)
                                .frame(width: swipeExpandAmount)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .clipped()
        }
    }

    private var swipeSkipIcon: some View {
        Image(systemName: rawTranslation > 0 ? "forward.end.fill" : "backward.end.fill")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .opacity(arrowOpacity)
            .scaleEffect(arrowScale)
    }

    private func handleHorizontalSwipeChanged(_ value: DragGesture.Value) {
        processSwipeChanged(translationX: value.translation.width, translationY: value.translation.height)
    }

    private func handleHorizontalSwipeEnded(_ value: DragGesture.Value) {
        let translation = rawTranslation == 0 ? value.translation.width : rawTranslation
        let velocity: CGFloat
        if abs(swipeVelocity) > 0 {
            velocity = swipeVelocity
        } else {
            velocity = (value.predictedEndTranslation.width - value.translation.width) / 0.1
        }
        processSwipeEnded(translationX: translation, velocity: velocity)
    }

    private func processSwipeChanged(translationX: CGFloat, translationY: CGFloat) {
        guard Defaults[.enableSwipeToSkip] else { return }
        guard vm.notchState == .closed else { return }
        guard vm.effectiveClosedNotchHeight > 0, !vm.hideOnClosed else { return }
        guard !isNotchTransitioning else { return }
        guard isSwipeMediaSessionActive else { return }
        guard !isSwipeDebounced else { return }
        if case .committing = swipePhase { return }
        if case .cancelling = swipePhase { return }

        if case .idle = swipePhase {
            swipePhase = .dragging(direction: .undetermined)
            swipeVelocity = 0
            lastVelocitySample = nil
        }

        updateSwipeVelocitySample(translationWidth: translationX)

        if !isDirectionLocked {
            let absX = abs(translationX)
            let absY = abs(translationY)
            let maxDelta = max(absX, absY)
            guard maxDelta >= swipeDirectionLockDistance else { return }

            isDirectionLocked = true
            if absX > absY * swipeDirectionDominanceFactor {
                lockedDirection = .horizontal
                swipePhase = .dragging(direction: .horizontal)
            } else {
                lockedDirection = .vertical
                swipePhase = .dragging(direction: .vertical)
                return
            }
        }

        guard lockedDirection == .horizontal else { return }
        updateSwipeVisuals(for: translationX)
    }

    private func processSwipeEnded(translationX: CGFloat, velocity: CGFloat) {
        defer {
            lastVelocitySample = nil
            swipeVelocity = 0
        }

        guard Defaults[.enableSwipeToSkip], vm.notchState == .closed, vm.effectiveClosedNotchHeight > 0, !vm.hideOnClosed else {
            resetSwipeState(cancelCommit: true)
            return
        }
        guard isDirectionLocked, lockedDirection == .horizontal else {
            resetSwipeState(cancelCommit: false)
            return
        }

        let shouldCommit =
            abs(translationX) >= swipeSkipThreshold
            || (abs(velocity) > swipeVelocityThreshold && abs(translationX) > swipeFlickMinimumDistance)

        if shouldCommit {
            startSwipeCommit(for: translationX > 0 ? .next : .previous)
        } else {
            startSwipeCancel()
        }
    }

    private func updateSwipeVisuals(for translation: CGFloat) {
        rawTranslation = translation

        let effectiveTravel = max(0, abs(translation) - swipeCancelZone)
        let denominator = max(1, swipeSkipThreshold - swipeCancelZone)
        let progress = min(1, effectiveTravel / denominator)

        swipeExpandAmount = swipeExpandMaxWidth * progress
        arrowOpacity = progress

        swipeOffset = 0
        contentOpacity = 1

        // #region agent log
        agentDebugLogSwipeLayoutSnapshot(runId: "pre-fix")
        // #endregion

        let crossedThreshold = abs(translation) >= swipeSkipThreshold
        if crossedThreshold && !hasTriggeredThresholdHaptic {
            hasTriggeredThresholdHaptic = true
            performSwipeHaptic(.alignment)
            withAnimation(.easeOut(duration: 0.12)) {
                arrowScale = 1.25
            }
        } else if !crossedThreshold && hasTriggeredThresholdHaptic {
            hasTriggeredThresholdHaptic = false
            withAnimation(.easeOut(duration: 0.12)) {
                arrowScale = 1.0
            }
        }
    }

    private func startSwipeCommit(for action: SwipeSkipAction) {
        swipeCommitTask?.cancel()
        swipePhase = .committing
        hasTriggeredThresholdHaptic = false

        withAnimation(.easeIn(duration: 0.12)) {
            arrowOpacity = 0
            arrowScale = 1
        }

        let previousTrack = currentTrackSignature()
        swipeCommitTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }

            performSwipeAction(action)

            let changed = await waitForTrackChange(from: previousTrack)
            guard !Task.isCancelled else { return }

            if changed {
                performSwipeHaptic(.generic)
            } else {
                performSwipeHaptic(.generic)
                if !reduceMotionEnabled {
                    await runSwipeShake()
                }
            }

            let collapseAnimation: Animation = reduceMotionEnabled
                ? .easeInOut(duration: 0.2)
                : .spring(response: 0.3, dampingFraction: 0.8)

            withAnimation(collapseAnimation) {
                swipeExpandAmount = 0
            }
            try? await Task.sleep(for: .milliseconds(250))

            isDirectionLocked = false
            lockedDirection = .undetermined
            if changed {
                lastSuccessfulSwipeAt = Date()
            }
            resetSwipeState(cancelCommit: false)
        }
    }

    private func startSwipeCancel() {
        swipePhase = .cancelling
        isDirectionLocked = false
        lockedDirection = .undetermined
        hasTriggeredThresholdHaptic = false

        let animation: Animation = reduceMotionEnabled
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.3, dampingFraction: 0.7)

        withAnimation(animation) {
            swipeExpandAmount = 0
            swipeOffset = 0
            contentOpacity = 1
            arrowOpacity = 0
            arrowScale = 1
        }

        Task { @MainActor in
            let delayMs = reduceMotionEnabled ? 220 : 300
            try? await Task.sleep(for: .milliseconds(delayMs))
            resetSwipeState(cancelCommit: false)
        }
    }

    private func runSwipeShake() async {
        let values: [CGFloat] = [3, -3, 3, -3, 0]
        for value in values {
            withAnimation(.easeInOut(duration: 0.03)) {
                swipeShakeOffset = value
            }
            try? await Task.sleep(for: .milliseconds(30))
        }
    }

    private func runBlankNotchFlash() {
        withAnimation(.easeOut(duration: 0.1)) {
            blankNotchFlashOpacity = 0.15
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.easeOut(duration: 0.1)) {
                blankNotchFlashOpacity = 0
            }
        }
    }

    private func performSwipeAction(_ action: SwipeSkipAction) {
        switch action {
        case .next:
            MusicManager.shared.nextTrack()
        case .previous:
            MusicManager.shared.previousTrack()
        }
    }

    private func currentTrackSignature() -> TrackSignature {
        TrackSignature(
            title: musicManager.songTitle,
            artist: musicManager.artistName,
            album: musicManager.album,
            bundleIdentifier: musicManager.bundleIdentifier
        )
    }

    private func waitForTrackChange(from previous: TrackSignature) async -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < swipeTrackChangeTimeoutSeconds {
            if currentTrackSignature() != previous {
                return true
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return currentTrackSignature() != previous
    }

    private func updateSwipeVelocitySample(translationWidth: CGFloat) {
        let now = Date()
        if let previous = lastVelocitySample {
            let deltaTime = now.timeIntervalSince(previous.timestamp)
            if deltaTime > 0 {
                swipeVelocity = (translationWidth - previous.translation) / deltaTime
            }
        }
        lastVelocitySample = SwipeVelocitySample(translation: translationWidth, timestamp: now)
    }

    private func dampedSwipeOffset(_ translation: CGFloat) -> CGFloat {
        let maxOffset = swipeVisualMaxOffset
        let sign: CGFloat = translation >= 0 ? 1 : -1
        let absTranslation = abs(translation)
        let damped = maxOffset * (1 - exp(-absTranslation / maxOffset))
        return sign * damped
    }

    private func performSwipeHaptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        guard Defaults[.enableHaptics], Defaults[.swipeHapticFeedback] else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }

    // #region agent log
    private func agentDebugLogNDJSON(hypothesisId: String, message: String, data: [String: Any], runId: String) {
        var payload: [String: Any] = [
            "sessionId": "eead00",
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": "ContentView.swift",
            "message": message,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "data": data
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              var line = String(data: jsonData, encoding: .utf8) else { return }
        line.append("\n")
        let path = "/Users/marvinbarsal/Desktop/Gaming/NotchX/.cursor/debug-eead00.log"
        let url = URL(fileURLWithPath: path)
        guard let lineData = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: path) {
            guard let fh = try? FileHandle(forWritingTo: url) else { return }
            defer { try? fh.close() }
            try? fh.seekToEnd()
            try? fh.write(contentsOf: lineData)
        } else {
            try? lineData.write(to: url)
        }
    }

    private func agentDebugLogSwipeLayoutSnapshot(runId: String) {
        let closedBasePad = cornerRadiusInsets.closed.bottom
        let swipeLeadingExtra: CGFloat = (vm.notchState == .closed && rawTranslation < 0) ? swipeExpandAmount : 0
        let swipeTrailingExtra: CGFloat = (vm.notchState == .closed && rawTranslation > 0) ? swipeExpandAmount : 0
        let maxWidthFrame = computedChinWidth + extendedHoverPadding * 2 + swipeExpandAmount
        let innerWidthAfterPadding = maxWidthFrame - closedBasePad - swipeLeadingExtra - closedBasePad - swipeTrailingExtra
        let middleRectW = vm.closedNotchSize.width + -cornerRadiusInsets.closed.top
        let coverSize = max(0, vm.effectiveClosedNotchHeight - 12)
        let coverDisplay = isHoveringClosedMusicCover ? coverSize + 6 : coverSize
        let zstackW = max(0, vm.effectiveClosedNotchHeight - 12 + gestureProgress / 2)
        let hStackSpacing: CGFloat = 8
        let hstackApproxSum = coverDisplay + 2 + hStackSpacing + middleRectW + hStackSpacing + zstackW
        var data: [String: Any] = [
            "rawTranslation": Double(rawTranslation),
            "swipeExpandAmount": Double(swipeExpandAmount),
            "swipeExpandEdgeOffset": Double(swipeExpandEdgeOffset),
            "computedChinWidth": Double(computedChinWidth),
            "maxWidthFrame": Double(maxWidthFrame),
            "innerWidthAfterPadding": Double(innerWidthAfterPadding),
            "swipeLeadingExtra": Double(swipeLeadingExtra),
            "swipeTrailingExtra": Double(swipeTrailingExtra),
            "middleRectWidth": Double(middleRectW),
            "waveColumnWidth": Double(zstackW),
            "coverDisplay": Double(coverDisplay),
            "hstackApproxSum": Double(hstackApproxSum),
            "innerMinusHstack": Double(innerWidthAfterPadding - hstackApproxSum),
            "gestureProgress": Double(gestureProgress),
            "closedHoverScale": Double(closedHoverScale),
            "effectiveClosedNotchHeight": Double(vm.effectiveClosedNotchHeight),
            "isHoveringWaves": isHoveringWaves,
            "musicLiveActivityEnabled": coordinator.musicLiveActivityEnabled
        ]
        agentDebugLogNDJSON(hypothesisId: "H1-H5", message: "swipe layout snapshot", data: data, runId: runId)
    }
    // #endregion

    private func resetSwipeState(cancelCommit: Bool = true) {
        if cancelCommit {
            swipeCommitTask?.cancel()
        }
        swipeCommitTask = nil

        let wasHorizontalSwipe = lockedDirection == .horizontal

        swipePhase = .idle
        swipeOffset = 0
        rawTranslation = 0
        hasTriggeredThresholdHaptic = false
        isDirectionLocked = false
        lockedDirection = .undetermined
        arrowOpacity = 0
        arrowScale = 1
        contentOpacity = 1
        swipeExpandAmount = 0
        lastVelocitySample = nil
        swipeVelocity = 0
        swipeShakeOffset = 0
        blankNotchFlashOpacity = 0

        if wasHorizontalSwipe && vm.notchState == .closed {
            withAnimation(closedHoverAnimation) {
                closedHoverScale = 1.0
            }
        }
    }

    @ViewBuilder
    func NotchXFaceAnimation() -> some View {
        HStack {
            HStack {
                Rectangle()
                    .fill(.clear)
                    .frame(
                        width: max(0, vm.effectiveClosedNotchHeight - 12),
                        height: max(0, vm.effectiveClosedNotchHeight - 12)
                    )
                Rectangle()
                    .fill(.black)
                    .frame(width: vm.closedNotchSize.width - 20)
                MinimalFaceFeatures()
            }
        }.frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
    }

    @ViewBuilder
    func MusicLiveActivity() -> some View {
        let closedCoverSize = max(0, vm.effectiveClosedNotchHeight - 12)
        let coverDisplaySize = isHoveringClosedMusicCover ? closedCoverSize + 6 : closedCoverSize
        HStack {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: MusicPlayerImageSizes.cornerRadiusInset.closed)
                )
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .frame(width: coverDisplaySize, height: coverDisplaySize)
                .animation(animationSpring, value: isHoveringClosedMusicCover)
                .padding(.leading, 2)
                .contentShape(Rectangle().inset(by: -6))
                .onHover { hovering in
                    withAnimation(animationSpring) {
                        isHoveringClosedMusicCover = hovering
                    }
                }

            Rectangle()
                .fill(.black)
                .overlay(
                    HStack(alignment: .top) {
                        if coordinator.expandingView.show
                            && coordinator.expandingView.type == .music
                        {
                            MarqueeText(
                                .constant(musicManager.songTitle),
                                textColor: Defaults[.coloredSpectrogram]
                                    ? Color(nsColor: musicManager.avgColor) : Color.gray,
                                minDuration: 0.4,
                                frameWidth: 100
                            )
                            .opacity(
                                (coordinator.expandingView.show
                                    && Defaults[.sneakPeekStyles] == .inline)
                                    ? 1 : 0
                            )
                            Spacer(minLength: vm.closedNotchSize.width)
                            // Song Artist
                            Text(musicManager.artistName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(
                                    Defaults[.coloredSpectrogram]
                                        ? Color(nsColor: musicManager.avgColor)
                                        : Color.gray
                                )
                                .opacity(
                                    (coordinator.expandingView.show
                                        && coordinator.expandingView.type == .music
                                        && Defaults[.sneakPeekStyles] == .inline)
                                        ? 1 : 0
                                )
                        }
                    }
                )
                .frame(
                    width: (coordinator.expandingView.show
                        && coordinator.expandingView.type == .music
                        && Defaults[.sneakPeekStyles] == .inline)
                        ? 380
                        : vm.closedNotchSize.width
                            + -cornerRadiusInsets.closed.top
                )

            ZStack {
                // Layer 1: Waves / Lottie animation
                HStack {
                    if useMusicVisualizer {
                        Rectangle()
                            .fill(
                                Defaults[.coloredSpectrogram]
                                    ? Color(nsColor: musicManager.avgColor).gradient
                                    : Color.gray.gradient
                            )
                            .frame(width: 50, alignment: .center)
                            .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
                            .mask {
                                AudioSpectrumView(isPlaying: $musicManager.isPlaying)
                                    .frame(width: 16, height: 12)
                            }
                    } else {
                        LottieAnimationContainer()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .opacity(isHoveringWaves ? 0 : 1)

                // Layer 2: Play/Pause button on hover (full-area hit target)
                Button {
                    MusicManager.shared.togglePlay()
                } label: {
                    Color.clear
                        .overlay {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(
                                    Defaults[.coloredSpectrogram]
                                        ? Color(nsColor: musicManager.avgColor)
                                        : Color.gray
                                )
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isHoveringWaves ? 1 : 0)
            }
            .frame(
                width: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                        + gestureProgress / 2
                ),
                height: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                ),
                alignment: .center
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.15)) {
                    isHoveringWaves = hovering
                }
            }
        }
        .frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
        // #region agent log
        .onChange(of: isHoveringWaves) { _, new in
            agentDebugLogNDJSON(
                hypothesisId: "H6",
                message: "isHoveringWaves toggled",
                data: [
                    "isHoveringWaves": new,
                    "swipeExpandAmount": Double(swipeExpandAmount),
                    "rawTranslation": Double(rawTranslation)
                ],
                runId: "pre-fix"
            )
        }
        // #endregion
    }

    @ViewBuilder
    var dragDetector: some View {
        if Defaults[.notchXShelf] && vm.notchState == .closed {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], isTargeted: $vm.dragDetectorTargeting) { providers in
            vm.dropEvent = true
            ShelfStateViewModel.shared.load(providers)
            return true
        }
        } else {
            EmptyView()
        }
    }

    private func doOpen() {
        pendingOpenTask?.cancel()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            closedHoverScale = 1.0
        }
        isNotchTransitioning = true

        pendingOpenTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(animationSpring) {
                vm.open()
            }
        }
    }

    private func closeNotch() {
        isNotchTransitioning = true
        resetClosedHoverScaleImmediately()
        vm.close()
    }

    private func resetClosedHoverScaleImmediately() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            closedHoverScale = 1.0
        }
    }

    private func scheduleNotchTransitionWindow(for newState: NotchState) {
        notchTransitionTask?.cancel()
        isNotchTransitioning = true

        notchTransitionTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                isNotchTransitioning = false

                guard newState == .closed && isHovering else { return }
                withAnimation(closedHoverAnimation) {
                    closedHoverScale = 1.05
                }
            }
        }
    }

    // MARK: - Hover Management

    private func handleHover(_ hovering: Bool) {
        if coordinator.firstLaunch { return }
        hoverTask?.cancel()

        if shouldSuppressClosedHoverFromSwipe {
            return
        }

        if hovering {
            withAnimation(animationSpring) {
                isHovering = true
            }
            
            if vm.notchState == .closed && !isNotchTransitioning {
                withAnimation(closedHoverAnimation) {
                    closedHoverScale = closedNotchHoverScaleFactor
                }
                if Defaults[.enableHaptics] {
                    haptics.toggle()
                }
            } else {
                resetClosedHoverScaleImmediately()
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(animationSpring) {
                        self.isHovering = false
                    }
                    if self.vm.notchState == .closed && !self.isNotchTransitioning {
                        withAnimation(self.closedHoverAnimation) {
                            self.closedHoverScale = 1.0
                        }
                    } else {
                        self.resetClosedHoverScaleImmediately()
                    }

                    if self.vm.notchState == .open && !self.vm.isBatteryPopoverActive && !self.vm.isBluetoothPopoverActive && !SharingStateManager.shared.preventNotchClose && !self.isNotchLocked {
                        self.closeNotch()
                    }
                }
            }
        }
    }

    // MARK: - Gesture Handling

    private func handleDownGesture(translation: CGFloat, phase: NSEvent.Phase) {
        guard vm.notchState == .closed else { return }
        guard !shouldSuppressClosedHoverFromSwipe else { return }
        if case .committing = swipePhase { return }
        if case .cancelling = swipePhase { return }

        if phase == .ended {
            withAnimation(animationSpring) { gestureProgress = .zero }
            return
        }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * 20
        }

        if translation > Defaults[.gestureSensitivity] {
            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
            doOpen()
        }
    }

    private func handleUpGesture(translation: CGFloat, phase: NSEvent.Phase) {
        guard vm.notchState == .open && !vm.isHoveringCalendar else { return }
        if SharingStateManager.shared.preventNotchClose || isNotchLocked { return }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * -20
        }

        if phase == .ended {
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
        }

        if translation > Defaults[.gestureSensitivity] {
            withAnimation(animationSpring) {
                isHovering = false
            }
            if !SharingStateManager.shared.preventNotchClose && !isNotchLocked {
                gestureProgress = .zero
                closeNotch()
            }

            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
        }
    }
}

struct FullScreenDropDelegate: DropDelegate {
    @Binding var isTargeted: Bool
    let onDrop: () -> Void

    func dropEntered(info _: DropInfo) {
        isTargeted = true
    }

    func dropExited(info _: DropInfo) {
        isTargeted = false
    }

    func performDrop(info _: DropInfo) -> Bool {
        isTargeted = false
        onDrop()
        return true
    }

}

struct GeneralDropTargetDelegate: DropDelegate {
    @Binding var isTargeted: Bool

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .cancel)
    }

    func performDrop(info: DropInfo) -> Bool {
        return false
    }
}

// MARK: - Blur Transition Modifier

struct BlurTransitionModifier: ViewModifier {
    let blurRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
    }
}

#Preview {
    let vm = NotchXViewModel()
    vm.open()
    return ContentView()
        .environmentObject(vm)
        .frame(width: vm.notchSize.width, height: vm.notchSize.height)
}
