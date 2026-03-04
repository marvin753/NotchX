//
//  CalendarSettingsPage.swift
//  NotchX
//
//  Calendar and Reminders settings page, redesigned with the NX design system.
//  Extracted from SettingsView.swift's `CalendarSettings` struct.
//  Also owns the `lighterColor(from:amount:)` helper (removed from SettingsView.swift).
//

import Defaults
import SwiftUI

// MARK: - CalendarSettings

struct CalendarSettings: View {

    // MARK: - Dependencies

    @ObservedObject private var calendarManager = CalendarManager.shared

    // MARK: - Defaults

    @Default(.showCalendar) private var showCalendar: Bool
    @Default(.hideCompletedReminders) private var hideCompletedReminders
    @Default(.hideAllDayEvents) private var hideAllDayEvents
    @Default(.autoScrollToNextEvent) private var autoScrollToNextEvent

    // MARK: - Body

    var body: some View {
        Form {
            generalSection
            calendarsSection
            remindersSection
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Calendar")
        .onAppear {
            Task {
                await calendarManager.checkCalendarAuthorization()
                await calendarManager.checkReminderAuthorization()
            }
        }
    }

    // MARK: - General Section

    @ViewBuilder
    private var generalSection: some View {
        Section {
            NXStyledToggle(title: "Show calendar", key: .showCalendar)
            NXStyledToggle(title: "Hide completed reminders", key: .hideCompletedReminders)
            NXStyledToggle(title: "Hide all-day events", key: .hideAllDayEvents)
            NXStyledToggle(title: "Auto-scroll to next event", key: .autoScrollToNextEvent)
            NXStyledToggle(title: "Always show full event titles", key: .showFullEventTitles)
        } header: {
            NXSectionHeader(title: "General")
        }
    }

    // MARK: - Calendars Section

    @ViewBuilder
    private var calendarsSection: some View {
        Section {
            if calendarManager.calendarAuthorizationStatus != .fullAccess {
                calendarAccessDeniedView
            } else {
                List {
                    ForEach(calendarManager.eventCalendars, id: \.id) { calendar in
                        calendarRow(for: calendar)
                    }
                }
            }
        } header: {
            NXSectionHeader(title: "Calendars")
        }
    }

    // MARK: - Reminders Section

    @ViewBuilder
    private var remindersSection: some View {
        Section {
            if calendarManager.reminderAuthorizationStatus != .fullAccess {
                reminderAccessDeniedView
            } else {
                List {
                    ForEach(calendarManager.reminderLists, id: \.id) { calendar in
                        calendarRow(for: calendar)
                    }
                }
            }
        } header: {
            NXSectionHeader(title: "Reminders")
        }
    }

    // MARK: - Shared Row Builder

    @ViewBuilder
    private func calendarRow(for calendar: CalendarModel) -> some View {
        Toggle(isOn: Binding(
            get: { calendarManager.getCalendarSelected(calendar) },
            set: { isSelected in
                Task { await calendarManager.setCalendarSelected(calendar, isSelected: isSelected) }
            }
        )) {
            HStack(spacing: 8) {
                Circle()
                    .fill(lighterColor(from: calendar.color))
                    .frame(width: 8, height: 8)
                Text(calendar.title)
            }
        }
        .accentColor(lighterColor(from: calendar.color))
        .disabled(!showCalendar)
    }

    // MARK: - Access Denied Views

    private var calendarAccessDeniedView: some View {
        VStack(spacing: 12) {
            Text("Calendar access is denied. Please enable it in System Settings.")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            Button("Open Calendar Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private var reminderAccessDeniedView: some View {
        VStack(spacing: 12) {
            Text("Reminder access is denied. Please enable it in System Settings.")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            Button("Open Reminder Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - lighterColor Helper

/// Returns a SwiftUI `Color` that is a lightened version of the given `NSColor`.
///
/// Each RGB channel is increased toward 1.0 by `amount` (0–1), producing a
/// pastel/washed-out tint suitable for calendar color accents.
func lighterColor(from nsColor: NSColor, amount: CGFloat = 0.14) -> Color {
    let srgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
    var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
    srgb.getRed(&r, green: &g, blue: &b, alpha: &a)

    func lighten(_ c: CGFloat) -> CGFloat {
        min(max(c + (1.0 - c) * amount, 0), 1)
    }

    return Color(
        red: Double(lighten(r)),
        green: Double(lighten(g)),
        blue: Double(lighten(b)),
        opacity: Double(a)
    )
}
