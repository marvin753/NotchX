//
//  ShelfSettingsPage.swift
//  NotchX
//

import Defaults
import SwiftUI

struct Shelf: View {
    @Default(.shelfTapToOpen) var shelfTapToOpen: Bool
    @Default(.quickShareProvider) var quickShareProvider
    @Default(.expandedDragDetection) var expandedDragDetection: Bool
    @StateObject private var quickShareService = QuickShareService.shared

    private var selectedProvider: QuickShareProvider? {
        quickShareService.availableProviders.first(where: { $0.id == quickShareProvider })
    }

    init() {
        Task { await QuickShareService.shared.discoverAvailableProviders() }
    }

    var body: some View {
        Form {
            Section {
                NXStyledToggle(title: "Enable shelf", key: .notchXShelf)
                NXStyledToggle(title: "Open shelf by default if items are present", key: .openShelfByDefault)
                NXStyledToggle(title: "Expanded drag detection area", key: .expandedDragDetection)
                    .onChange(of: expandedDragDetection) {
                        NotificationCenter.default.post(
                            name: Notification.Name.expandedDragDetectionChanged,
                            object: nil
                        )
                    }
                NXStyledToggle(title: "Copy items on drag", key: .copyOnDrag)
                NXStyledToggle(title: "Remove from shelf after dragging", key: .autoRemoveShelfItems)
            } header: {
                NXSectionHeader(title: "General")
            }

            Section {
                Picker("Quick Share Service", selection: $quickShareProvider) {
                    ForEach(quickShareService.availableProviders, id: \.id) { provider in
                        HStack {
                            Group {
                                if let imgData = provider.imageData, let nsImg = NSImage(data: imgData) {
                                    Image(nsImage: nsImg).resizable().aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                            .frame(width: 16, height: 16)
                            .foregroundColor(.accentColor)
                            Text(provider.id)
                        }
                        .tag(provider.id)
                    }
                }
                .pickerStyle(.menu)

                if let selectedProvider = selectedProvider {
                    HStack {
                        Group {
                            if let imgData = selectedProvider.imageData, let nsImg = NSImage(data: imgData) {
                                Image(nsImage: nsImg).resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .frame(width: 16, height: 16)
                        .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Currently selected: \(selectedProvider.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Files dropped on the shelf will be shared via this service")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                NXSectionHeader(title: "Quick Share")
            } footer: {
                Text("Choose which service to use when sharing files from the shelf.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Shelf")
    }
}
