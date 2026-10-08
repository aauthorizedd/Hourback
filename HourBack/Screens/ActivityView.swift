import SwiftUI

struct ActivityView: View {
    var model: AppModel

    var body: some View {
        HourBackScreen {
            if model.stats.averageHoursBack == 0 && model.stats.today == 0 && model.stats.dayByDay.allSatisfy({ $0.duration == 0 }) {
                Text("No hours back yet.")
                    .font(Typography.body)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Average hours back")
                    .font(Typography.body)
                Text(StatsCalculator.format(model.stats.averageHoursBack))
                    .font(Typography.bigNumber)
            }

            VStack(alignment: .leading, spacing: 0) {
                statRow("Today", model.stats.today)
                statRow("Yesterday", model.stats.yesterday)
                statRow("This week", model.stats.thisWeek)
                statRow("This month", model.stats.thisMonth)
                statRow("Last month", model.stats.lastMonth)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Day by day")
                    .font(Typography.body)
                ForEach(model.stats.dayByDay, id: \.day) { item in
                    HStack {
                        Text(item.day.formatted(.dateTime.month(.abbreviated).day().year()))
                        Spacer()
                        Text(StatsCalculator.format(item.duration))
                    }
                    .font(Typography.body)
                    Hairline()
                }
            }
        }
        .navigationTitle("Activity")
    }

    private func statRow(_ title: String, _ duration: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Text(StatsCalculator.format(duration))
            }
            .font(Typography.body)
            .padding(.vertical, 12)
            Hairline()
        }
    }
}
