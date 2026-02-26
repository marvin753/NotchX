//
//  NotchXCalendar.swift
//  NotchX
//
//  Created by Harsh Vardhan  Goswami  on 08/09/24.
//

import Defaults
import SwiftUI

struct Config: Equatable {
    //    var count: Int = 10  // 3 days past + today + 7 days future
    var past: Int = 7
    var future: Int = 14
    var steps: Int = 1  // Each step is one day
    var spacing: CGFloat = 4  // 🎯 SPACING CONTROL: Abstand zwischen einzelnen Tagen (Standard: 4, kleiner = mehr Tage sichtbar)
    var showsText: Bool = true
}

struct WheelPicker: View {
    @EnvironmentObject var vm: NotchXViewModel
    @Binding var selectedDate: Date
    @Binding var scrollPosition: Int?  // Now accepts binding from parent
    @State private var haptics: Bool = false
    @State private var byClick: Bool = false
    @State private var visibleWidth: CGFloat = 215  // safe default matching preview
    // 🎯 ITEM WIDTH CONTROL: Breite jedes einzelnen Tages (Standard: 28, kleiner = mehr Tage sichtbar)
    private let itemWidth: CGFloat = 28  // Fixed width for all items
    private var edgePadding: CGFloat { max(0, (visibleWidth / 2) - (itemWidth / 2)) }
    private let centerOffset: CGFloat = 0  // positiv = nach rechts
    let config: Config
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: config.spacing) {
                    ForEach(0..<totalDateItems(), id: \.self) { index in
                        let date = dateForItemIndex(index: index)
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        dateButton(date: date, isSelected: isSelected, id: index) {
                            selectedDate = date
                            byClick = true
                            withAnimation {
                                scrollPosition = index
                            }
                            if Defaults[.enableHaptics] {
                                haptics.toggle()
                            }
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.never)
            .contentMargins(.leading,  edgePadding + centerOffset, for: .scrollContent)
            .contentMargins(.trailing, edgePadding - centerOffset, for: .scrollContent)
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .sensoryFeedback(.alignment, trigger: haptics)
            .onChange(of: scrollPosition) { oldValue, newValue in
                if !byClick {
                    handleScrollChange(newValue: newValue, config: config)
                } else {
                    byClick = false
                }
            }
            .onAppear {
                visibleWidth = geo.size.width
                scrollToToday(config: config)
            }
            .onChange(of: geo.size.width) { _, new in visibleWidth = new }
            // When parent updates the bound selectedDate (e.g., view reopen), center the wheel on it
            .onChange(of: selectedDate) { _, newValue in
                let targetIndex = indexForDate(newValue)
                if scrollPosition != targetIndex {
                    byClick = true
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollPosition = targetIndex
                        }
                    }
                }
            }
        }
        .frame(height: 50)
    }

    private func dateButton(
        date: Date, isSelected: Bool, id: Int, onClick: @escaping () -> Void
    ) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        return Button(action: onClick) {
            VStack(spacing: 2) {
                dayText(date: dateToString(for: date, isSelected: isSelected), isToday: isToday, isSelected: isSelected)
                dateCircle(date: date, isToday: isToday, isSelected: isSelected)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)  // Fill available space
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: itemWidth)  // Fixed width for consistent scrolling
        .id(id)
    }

    private func dayText(date: String, isToday: Bool, isSelected: Bool) -> some View {
        Text(date)
            .font(isSelected ? .caption : .caption2)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(
                isToday ? Color.effectiveAccent :
                isSelected ? .white : Color(white: 0.5)
            )
            // 🎯 ANIMATION CONTROL: Smoothere Animation mit Spring-Effekt
            .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0), value: isSelected)
    }

    private func dateCircle(date: Date, isToday: Bool, isSelected: Bool) -> some View {
        Text("\(date.date)")
            .font(isSelected ? .title2 : .body)
            .fontWeight(isSelected ? .semibold : .medium)
            .foregroundColor(
                isToday ? Color.effectiveAccent :
                isSelected ? .white : Color(white: 0.5)
            )
            // 🎯 ANIMATION CONTROL: Smoothere Animation mit Spring-Effekt
            .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0), value: isSelected)
    }

    func handleScrollChange(newValue: Int?, config: Config) {
        guard let newIndex = newValue else { return }
        let dateCount = totalDateItems()
        guard (0..<dateCount).contains(newIndex) else { return }
        let date = dateForItemIndex(index: newIndex)
        if !Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            selectedDate = date
            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
        }
    }

    private func scrollToToday(config: Config) {
        let today = Date()
        selectedDate = today
        byClick = true
        DispatchQueue.main.async {
            scrollPosition = indexForDate(today)
        }
    }

    // MARK: - Index/Date mapping with steps
    private func indexForDate(_ date: Date) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let startDate = cal.startOfDay(for: cal.date(byAdding: .day, value: -config.past, to: today) ?? today)
        let target = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: startDate, to: target).day ?? 0
        let stepIndex = max(0, min(days / max(config.steps, 1), totalDateItems() - 1))
        return stepIndex
    }

    private func dateForItemIndex(index: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let startDate = cal.date(byAdding: .day, value: -config.past, to: today) ?? today
        let stepIndex = index
        return cal.date(byAdding: .day, value: stepIndex * max(config.steps, 1), to: startDate) ?? today
    }

    private func totalDateItems() -> Int {
        let range = config.past + config.future
        let step = max(config.steps, 1)
        return Int(ceil(Double(range) / Double(step))) + 1
    }

    private func dateToString(for date: Date, isSelected: Bool) -> String {
        let formatter = DateFormatter()
        // Zweistellige Abkürzung (Mo, Di, Mi, etc.)
        formatter.dateFormat = isSelected ? "EE" : "EEEEE"
        return formatter.string(from: date).uppercased()
    }
}

struct CalendarView: View {
    @EnvironmentObject var vm: NotchXViewModel
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Environment(\.openURL) private var openURL
    @State private var selectedDate = Date()
    @State private var scrollPosition: Int?  // Shared scroll position state

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // WheelPicker fills full width
                    ZStack(alignment: .top) {
                        WheelPicker(selectedDate: $selectedDate, scrollPosition: $scrollPosition, config: Config())
                        HStack(alignment: .top) {
                            LinearGradient(
                                colors: [Color.black, Color.black.opacity(0.6), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: 40)
                            Spacer()
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.6), Color.black],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: 40)
                        }
                        .allowsHitTesting(false)
                    }

                    // Month gradient background - visual only, doesn't block scroll
                    LinearGradient(
                        stops: [
                            .init(color: Color.black, location: 0.0),
                            .init(color: Color.black.opacity(0.95), location: 0.2),
                            .init(color: Color.black.opacity(0.75), location: 0.35),
                            .init(color: Color.black.opacity(0.5), location: 0.5),
                            .init(color: Color.black.opacity(0.25), location: 0.65),
                            .init(color: Color.black.opacity(0.1), location: 0.8),
                            .init(color: .clear, location: 1.0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: 120, height: 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)

                    // Month label - tappable text only, scroll events pass through
                    Text(selectedDate.formatted(.dateTime.month(.abbreviated)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                        .onTapGesture { openCalendarApp() }
                }
                .padding(.bottom, 6)

                let filteredEvents = EventListView.filteredEvents(
                    events: calendarManager.events
                )
                if filteredEvents.isEmpty {
                    EmptyEventsView(selectedDate: selectedDate)
                    Spacer(minLength: 0)
                } else {
                    EventListView(events: calendarManager.events)
                }
            }
        }
        .listRowBackground(Color.clear)
        .frame(height: 130)
        .onChange(of: selectedDate) {
            Task {
                await calendarManager.updateCurrentDate(selectedDate)
            }
        }
        .onChange(of: vm.notchState) { _, _ in
            Task {
                await calendarManager.updateCurrentDate(Date.now)
                selectedDate = Date.now
            }
        }
        .onAppear {
            Task {
                await calendarManager.updateCurrentDate(Date.now)
                selectedDate = Date.now
            }
        }
    }
    
    // Open Calendar app to show selected date
    private func openCalendarApp() {
        #if os(macOS)
        // On macOS, use NSWorkspace to open Calendar.app
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        #else
        // On iOS, use the calendar URL scheme
        let interval = selectedDate.timeIntervalSinceReferenceDate
        if let url = URL(string: "calshow:\(interval)") {
            openURL(url)
        }
        #endif
    }
    
}

struct EmptyEventsView: View {
    let selectedDate: Date
    
    var body: some View {
        VStack {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title)
                .foregroundColor(Color(white: 0.65))
            Text(Calendar.current.isDateInToday(selectedDate) ? "No events today" : "No events")
                .font(.subheadline)
                .foregroundColor(.white)
            Text("Enjoy your free time!")
                .font(.caption)
                .foregroundColor(Color(white: 0.65))
        }
    }
}

struct EventListView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject private var calendarManager = CalendarManager.shared
    let events: [EventModel]
    @Default(.autoScrollToNextEvent) private var autoScrollToNextEvent
    @Default(.showFullEventTitles) private var showFullEventTitles


    static func filteredEvents(events: [EventModel]) -> [EventModel] {
        events.filter { event in
            if event.type.isReminder {
                if case .reminder(let completed) = event.type {
                    return !completed || !Defaults[.hideCompletedReminders]
                }
            }
            // Filter out all-day events if setting is enabled
            if event.isAllDay && Defaults[.hideAllDayEvents] {
                return false
            }
            return true
        }
    }

    private var filteredEvents: [EventModel] {
        Self.filteredEvents(events: events)
    }

    private func scrollToRelevantEvent(proxy: ScrollViewProxy) {
        let now = Date()
        // Determine a single target using preferred search order:
        // 1) first non-all-day upcoming/in-progress event
        // 2) first all-day event
        // 3) last event (fallback)
        let nonAllDayUpcoming = filteredEvents.first(where: { !$0.isAllDay && $0.end > now })
        let firstAllDay = filteredEvents.first(where: { $0.isAllDay })
        let lastEvent = filteredEvents.last
        guard let target = nonAllDayUpcoming ?? firstAllDay ?? lastEvent else { return }

        Task { @MainActor in
            withTransaction(Transaction(animation: nil)) {
                proxy.scrollTo(target.id, anchor: .top)
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredEvents) { event in
                    Button(action: {
                        if let url = event.calendarAppURL() {
                            openURL(url)
                        }
                    }) {
                        eventRow(event)
                    }
                    .id(event.id)
                    .padding(.leading, -5)
                    .buttonStyle(PlainButtonStyle())
                    .listRowSeparator(.automatic)
                    .listRowSeparatorTint(.gray.opacity(0.2))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.never)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onAppear {
                scrollToRelevantEvent(proxy: proxy)
            }
            .onChange(of: filteredEvents) { _, _ in
                scrollToRelevantEvent(proxy: proxy)
            }
        }
        Spacer(minLength: 0)
    }

    private func eventRow(_ event: EventModel) -> some View {
        if event.type.isReminder {
            let isCompleted: Bool
            if case .reminder(let completed) = event.type {
                isCompleted = completed
            } else {
                isCompleted = false
            }
            return AnyView(
                HStack(spacing: 8) {
                    ReminderToggle(
                        isOn: Binding(
                            get: { isCompleted },
                            set: { newValue in
                                Task {
                                    await calendarManager.setReminderCompleted(
                                        reminderID: event.id, completed: newValue
                                    )
                                }
                            }
                        ),
                        color: Color(event.calendar.color)
                    )
                    .opacity(1.0)  // Ensure the toggle is always fully opaque
                    HStack {
                        Text(event.title)
                            .font(.callout)
                            .foregroundColor(.white)
                            .lineLimit(showFullEventTitles ? nil : 1)
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 4) {
                            if event.isAllDay {
                                Text("All-day")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            } else {
                                Text(event.start, style: .time)
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                    .opacity(
                        isCompleted
                            ? 0.4
                            : event.start < Date.now && Calendar.current.isDateInToday(event.start)
                                ? 0.6 : 1.0
                    )
                }
                .padding(.vertical, 4)
            )
        } else {
            return AnyView(
                HStack(alignment: .top, spacing: 4) {
                    Rectangle()
                        .fill(Color(event.calendar.color))
                        .frame(width: 3)
                        .cornerRadius(1.5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(showFullEventTitles ? nil : 2)

                        if let location = event.location, !location.isEmpty {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(Color(white: 0.65))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 4) {
                        if event.isAllDay {
                            Text("All-day")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        } else {
                            Text(event.start, style: .time)
                                .foregroundColor(.white)
                            Text(event.end, style: .time)
                                .foregroundColor(Color(white: 0.65))
                        }
                    }
                    .font(.caption)
                    .frame(minWidth: 44, alignment: .trailing)
                }
                .opacity(
                    event.eventStatus == .ended && Calendar.current.isDateInToday(event.start)
                        ? 0.6 : 1.0)
            )
        }
    }
}

struct ReminderToggle: View {
    @Binding var isOn: Bool
    var color: Color

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(color, lineWidth: 2)
                    .frame(width: 14, height: 14)
                // Inner fill
                if isOn {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Circle()
                    .fill(Color.black.opacity(0.001))
                    .frame(width: 14, height: 14)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(0)
        .accessibilityLabel(isOn ? "Mark as incomplete" : "Mark as complete")
    }
}

#Preview {
    CalendarView()
        .frame(width: 215, height: 130)
        .background(.black)
        .environmentObject(NotchXViewModel())
}
