import Charts
import SwiftUI

struct CompactProgressChart: View {
    let exerciseName: String
    let history: [Workout]

    struct ChartPoint: Identifiable, Equatable {
        var id: String { "\(date.timeIntervalSince1970)-\(weight)" }
        let date: Date
        let weight: Double
    }

    var chartPoints: [ChartPoint] {
        let calendar = Calendar.current
        var dayToMaxWeight: [Date: Double] = [:]

        for workout in history {
            for exercise in workout.exercises where exercise.name == exerciseName {
                for set in exercise.sets {
                    if let reps = set.completedReps, reps > 0 {
                        let components = calendar.dateComponents([.year, .month, .day], from: workout.date)
                        if let dateOnly = calendar.date(from: components) {
                            let currentMax = dayToMaxWeight[dateOnly] ?? 0
                            dayToMaxWeight[dateOnly] = max(currentMax, exercise.weight)
                        }
                    }
                }
            }
        }

        return dayToMaxWeight
            .map { ChartPoint(date: $0.key, weight: $0.value) }
            .sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Progress for \(exerciseName)")
                .font(.headline)
                .foregroundColor(.white)

            ZStack(alignment: .trailing) {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbol(by: .value("Date", point.date))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", point.weight))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }

                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .border(Color.white.opacity(0.2), width: 1)
                }
                .chartXAxis {
                    AxisMarks(values: chartPoints.map { $0.date }) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.day().month()))
                            }
                        }
                        .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 300)
                .animation(.easeOut(duration: 3.0), value: chartPoints)
                Text("Weight (kg)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-90))
                    .offset(x: 38)
            }

            Text("Date")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color("AppBackground"))
    }
}