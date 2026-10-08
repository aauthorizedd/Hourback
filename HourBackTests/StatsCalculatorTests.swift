import XCTest
@testable import HourBack

final class StatsCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        self.calendar = calendar
    }

    func testMidnightSplit() {
        let now = date(2026, 10, 9, 12, 0)
        let session = SessionSpan(
            start: date(2026, 10, 8, 23, 0),
            end: date(2026, 10, 9, 1, 30)
        )
        let stats = StatsCalculator.snapshot(sessions: [session], now: now, calendar: calendar)
        XCTAssertEqual(stats.yesterday, 3_600, accuracy: 0.5)
        XCTAssertEqual(stats.today, 5_400, accuracy: 0.5)
        XCTAssertEqual(StatsCalculator.format(stats.yesterday), "1h 00m")
        XCTAssertEqual(StatsCalculator.format(stats.today), "1h 30m")
    }

    func testEmptyData() {
        let now = date(2026, 10, 8, 12, 0)
        let stats = StatsCalculator.snapshot(sessions: [], now: now, calendar: calendar)
        XCTAssertEqual(stats.today, 0)
        XCTAssertEqual(stats.yesterday, 0)
        XCTAssertEqual(stats.thisWeek, 0)
        XCTAssertEqual(stats.thisMonth, 0)
        XCTAssertEqual(stats.lastMonth, 0)
        XCTAssertEqual(stats.averageHoursBack, 0)
        XCTAssertEqual(stats.dayByDay.count, 30)
        XCTAssertTrue(stats.dayByDay.allSatisfy { $0.duration == 0 })
        XCTAssertEqual(StatsCalculator.format(0), "0h 00m")
        XCTAssertEqual(StatsCalculator.format(5 * 60), "0h 05m")
    }

    func testOpenSession() {
        let now = date(2026, 10, 8, 12, 14)
        let session = SessionSpan(start: date(2026, 10, 8, 10, 0), end: nil)
        let stats = StatsCalculator.snapshot(sessions: [session], now: now, calendar: calendar)
        XCTAssertEqual(stats.today, 8_040, accuracy: 0.5)
        XCTAssertEqual(StatsCalculator.format(stats.today), "2h 14m")
        XCTAssertEqual(stats.averageHoursBack, 8_040, accuracy: 0.5)
        XCTAssertEqual(stats.dayByDay.first?.duration ?? -1, 8_040, accuracy: 0.5)
    }

    func testWeekBoundaries() {
        let now = date(2026, 10, 8, 15, 0)
        let session = SessionSpan(
            start: date(2026, 10, 3, 22, 0),
            end: date(2026, 10, 4, 3, 0)
        )
        let stats = StatsCalculator.snapshot(sessions: [session], now: now, calendar: calendar)
        XCTAssertEqual(stats.thisWeek, 3 * 3_600, accuracy: 0.5)
        XCTAssertEqual(stats.thisMonth, 5 * 3_600, accuracy: 0.5)
        XCTAssertEqual(stats.lastMonth, 0, accuracy: 0.5)
        XCTAssertEqual(stats.today, 0, accuracy: 0.5)
        XCTAssertEqual(stats.yesterday, 0, accuracy: 0.5)
        XCTAssertEqual(duration(on: 10, 4, in: stats), 3 * 3_600, accuracy: 0.5)
        XCTAssertEqual(duration(on: 10, 3, in: stats), 2 * 3_600, accuracy: 0.5)
    }

    func testMockTagReaderReturnsTheScriptedIdentifier() async throws {
        let identifier = Data([0xAB, 0xCD])
        let reader = MockTagReader(identifier: identifier)
        let read = try await reader.readIdentifier(prompt: AppConfig.scanPrompt)
        XCTAssertEqual(read, identifier)
        XCTAssertEqual(TagHash.sha256Hex(identifier), TagHash.sha256Hex(identifier))
        XCTAssertNotEqual(TagHash.sha256Hex(identifier), TagHash.sha256Hex(Data([0xAB])))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func duration(on month: Int, _ day: Int, in stats: StatsSnapshot) -> TimeInterval {
        stats.dayByDay.first { item in
            calendar.component(.month, from: item.day) == month && calendar.component(.day, from: item.day) == day
        }?.duration ?? -1
    }
}
