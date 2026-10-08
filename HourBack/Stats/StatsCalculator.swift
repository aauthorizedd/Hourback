import Foundation

struct SessionSpan: Equatable {
    var start: Date
    var end: Date?
}

struct DayTotal: Equatable {
    var day: Date
    var duration: TimeInterval
}

struct StatsSnapshot: Equatable {
    var today: TimeInterval
    var yesterday: TimeInterval
    var thisWeek: TimeInterval
    var thisMonth: TimeInterval
    var lastMonth: TimeInterval
    var dayByDay: [DayTotal]
    var averageHoursBack: TimeInterval
}

enum StatsCalculator {
    static func snapshot(sessions: [SessionSpan], now: Date, calendar: Calendar) -> StatsSnapshot {
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
        let week = calendar.dateInterval(of: .weekOfYear, for: now)
        let month = calendar.dateInterval(of: .month, for: now)
        let lastMonthAnchor = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let lastMonth = calendar.dateInterval(of: .month, for: lastMonthAnchor)

        var days: [DayTotal] = []
        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            days.append(DayTotal(day: day, duration: total(sessions, from: day, to: min(next, now), now: now)))
        }

        return StatsSnapshot(
            today: total(sessions, from: todayStart, to: now, now: now),
            yesterday: total(sessions, from: yesterdayStart, to: todayStart, now: now),
            thisWeek: total(sessions, from: week?.start ?? todayStart, to: min(week?.end ?? now, now), now: now),
            thisMonth: total(sessions, from: month?.start ?? todayStart, to: min(month?.end ?? now, now), now: now),
            lastMonth: total(sessions, from: lastMonth?.start ?? yesterdayStart, to: min(lastMonth?.end ?? todayStart, now), now: now),
            dayByDay: days,
            averageHoursBack: average(sessions, now: now, calendar: calendar)
        )
    }

    static func format(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int(duration / 60))
        return String(format: "%dh %02dm", minutes / 60, minutes % 60)
    }

    private static func total(_ sessions: [SessionSpan], from start: Date, to end: Date, now: Date) -> TimeInterval {
        sessions.reduce(0) { $0 + clipped($1, from: start, to: end, now: now) }
    }

    private static func clipped(_ session: SessionSpan, from rangeStart: Date, to rangeEnd: Date, now: Date) -> TimeInterval {
        let sessionEnd = min(session.end ?? now, now)
        let start = max(session.start, rangeStart)
        let end = min(sessionEnd, rangeEnd)
        guard end > start else { return 0 }
        return end.timeIntervalSince(start)
    }

    private static func average(_ sessions: [SessionSpan], now: Date, calendar: Calendar) -> TimeInterval {
        guard let earliest = sessions.map(\.start).min(), now >= earliest else { return 0 }
        let firstDay = calendar.startOfDay(for: earliest)
        let today = calendar.startOfDay(for: now)
        let days = (calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0) + 1
        guard days > 0 else { return 0 }
        let overall = total(sessions, from: Date(timeIntervalSince1970: 0), to: now, now: now)
        return overall / Double(days)
    }
}
