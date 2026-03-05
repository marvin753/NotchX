//
//  NowPlayingSettingsPage.swift
//  NotchX
//
//  Now Playing settings page redesigned with the NX design system.
//  Extracted from SettingsView.swift's `NowPlayingSettings` struct.
//

import Defaults
import SwiftUI

struct NowPlayingSettings: View {

    // MARK: - Defaults

    @Default(.waitInterval) var waitInterval
    @Default(.mediaController) var mediaController
    @Default(.hideNotchOption) var hideNotchOption
    @Default(.enableSneakPeek) private var enableSneakPeek
    @Default(.sneakPeekStyles) var sneakPeekStyles
    @Default(.enableLyrics) var enableLyrics
    @Default(.coloredSpectrogram) var coloredSpectrogram
    @Default(.playerColorTinting) var playerColorTinting
    @Default(.lightingEffect) var lightingEffect
    @Default(.sliderColor) var sliderColor

    // MARK: - Dependencies

    @ObservedObject var coordinator = NotchXViewCoordinator.shared

    // MARK: - Body

    var body: some View {
        Form {
            mediaSourceSection
            liveActivitySection
            mediaControlsSection
            appearanceSection
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Now Playing")
    }

    // MARK: - Media Source

    @ViewBuilder
    private var mediaSourceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Music source")
                    .font(.body)

                HStack(spacing: 8) {
                    ForEach(availableMediaControllers) { controller in
                        MediaSourceTileCard(
                            controllerType: controller,
                            isSelected: mediaController == controller
                        ) {
                            withAnimation(.spring(duration: 0.25)) {
                                mediaController = controller
                            }
                        }
                    }
                }
                .onChange(of: mediaController) { _, _ in
                    NotificationCenter.default.post(
                        name: Notification.Name.mediaControllerChanged,
                        object: nil
                    )
                }
            }
        } header: {
            NXSectionHeader(title: "Media source")
        } footer: {
            if MusicManager.shared.isNowPlayingDeprecated {
                HStack {
                    Text("YouTube Music requires this third-party app to be installed: ")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Link(
                        "pear-desktop",
                        destination: URL(string: "https://github.com/pear-devs/pear-desktop")!
                    )
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Text(
                    "'Now Playing' was the only option on previous versions and works with all media apps."
                )
                .foregroundStyle(.secondary)
                .font(.caption)
            }
        }
    }

    // MARK: - Media Playback Live Activity

    @ViewBuilder
    private var liveActivitySection: some View {
        Section {
            NXStyledToggleBinding(
                title: "Show music live activity",
                isOn: $coordinator.musicLiveActivityEnabled.animation()
            )

            NXStyledToggleBinding(
                title: "Show sneak peek on playback changes",
                isOn: $enableSneakPeek
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Sneak peek style")
                    .font(.body)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "Default", value: SneakPeekStyle.standard) {
                            MiniSneakPeekDefault()
                                .scaleEffect(2.6)
                                .frame(width: 80, height: 50)
                                .clipped()
                        },
                        NXPreviewItem(label: "Inline", value: SneakPeekStyle.inline) {
                            MiniSneakPeekInline()
                                .scaleEffect(2.6)
                                .frame(width: 80, height: 50)
                                .clipped()
                        },
                    ],
                    selection: $sneakPeekStyles
                )
            }

            NXStepperField(
                title: "Media inactivity timeout",
                value: $waitInterval,
                range: 0...10,
                step: 1,
                unit: "s"
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Full screen behavior")
                        .font(.body)
                    customBadge(text: "Beta")
                }

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "All apps", value: HideNotchOption.always, icon: "rectangle.fill"),
                        NXPreviewItem(label: "Media only", value: HideNotchOption.nowPlayingOnly, icon: "rectangle.bottomhalf.inset.filled"),
                        NXPreviewItem(label: "Never", value: HideNotchOption.never, icon: "rectangle.slash"),
                    ],
                    selection: $hideNotchOption
                )
            }
        } header: {
            NXSectionHeader(title: "Media playback live activity")
        }
    }

    // MARK: - Media Controls

    @ViewBuilder
    private var mediaControlsSection: some View {
        Section {
            MusicSlotConfigurationView()

            NXStyledToggle(
                title: "Show lyrics below artist name",
                subtitle: "Beta",
                key: .enableLyrics
            )
        } header: {
            NXSectionHeader(title: "Media controls")
        } footer: {
            Text("Customize which controls appear in the music player. Volume expands when active.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Now Playing Appearance

    @ViewBuilder
    private var appearanceSection: some View {
        Section {
            NXStyledToggle(title: "Colored spectrogram", key: .coloredSpectrogram)

            NXStyledToggle(title: "Player tinting", key: .playerColorTinting)

            NXStyledToggle(
                title: "Enable blur effect behind album art",
                key: .lightingEffect
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Slider color")
                    .font(.body)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "White", value: SliderColorEnum.white) {
                            MiniSliderColorCircle(color: .white)
                                .scaleEffect(2.6)
                                .frame(width: 80, height: 50)
                                .clipped()
                        },
                        NXPreviewItem(label: "Album art", value: SliderColorEnum.albumArt) {
                            MiniSliderColorCircleMulticolor()
                                .scaleEffect(2.6)
                                .frame(width: 80, height: 50)
                                .clipped()
                        },
                        NXPreviewItem(label: "Accent", value: SliderColorEnum.accent) {
                            MiniSliderColorCircle(color: .effectiveAccent)
                                .scaleEffect(2.6)
                                .frame(width: 80, height: 50)
                                .clipped()
                        },
                    ],
                    selection: $sliderColor
                )
            }
        } header: {
            NXSectionHeader(title: "Now Playing appearance")
        }
    }

    // MARK: - Helpers

    private var availableMediaControllers: [MediaControllerType] {
        if MusicManager.shared.isNowPlayingDeprecated {
            return MediaControllerType.allCases.filter { $0 != .nowPlaying }
        } else {
            return MediaControllerType.allCases
        }
    }
}

// MARK: - Media Source Tile Card

private struct MediaSourceTileCard: View {
    let controllerType: MediaControllerType
    let isSelected: Bool
    let onSelect: () -> Void

    private var brandColor: Color {
        switch controllerType {
        case .nowPlaying:
            return Color.effectiveAccent
        case .appleMusic:
            return Color(red: 0.98, green: 0.24, blue: 0.35)
        case .spotify:
            return Color(red: 0.114, green: 0.725, blue: 0.329)
        case .youtubeMusic:
            return Color.red
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch controllerType {
        case .nowPlaying:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.effectiveAccent)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .appleMusic:
            Image("AppleMusicIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .spotify:
            Image("SpotifyIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .youtubeMusic:
            Image("YouTubeMusicIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Button(action: onSelect) {
                iconView
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(brandColor.opacity(isSelected ? 0.20 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.effectiveAccent : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help(controllerType.rawValue)

            Text(controllerType.rawValue)
                .font(.caption2)
                .fontWeight(isSelected ? .bold : .medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
    }
}

// MARK: - Mini-Preview: Sneak Peek

private struct MiniSneakPeekDefault: View {
    var body: some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(Color.primary.opacity(0.3))
                .frame(width: 20, height: 3)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.primary.opacity(0.15))
                .frame(width: 24, height: 9)
        }
        .frame(height: 18)
    }
}

private struct MiniSneakPeekInline: View {
    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.4))
            .frame(width: 28, height: 4)
            .frame(height: 18)
    }
}

// MARK: - Mini-Preview: Slider Color

private struct MiniSliderColorCircle: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .frame(height: 18)
    }
}

private struct MiniSliderColorCircleMulticolor: View {
    var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                    center: .center
                )
            )
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .frame(height: 18)
    }
}
