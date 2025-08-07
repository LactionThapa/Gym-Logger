import SwiftUI
import Charts

struct ProgressChartView: View {
    let exerciseName: String
    let history: [Workout]

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }

    var chartPoints: [ChartPoint] {
        var result: [ChartPoint] = []

        for workout in history {
            for exercise in workout.exercises where exercise.name == exerciseName {
                for set in exercise.sets {
                    if let reps = set.completedReps, reps > 0 {
                        let weight = exercise.weight
                        result.append(ChartPoint(date: workout.date, weight: weight))
                    }
                }
            }
        }

        return result.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress for \(exerciseName)")
                .font(.title2.bold())
                .foregroundColor(.white)

            Chart(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight (kg)", point.weight)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color("AppBackground")) // Chart area background
                    .border(Color.white.opacity(0.2), width: 1) // Optional border
            }
            .frame(height: 300)
            .chartXAxisLabel("Date", alignment: .center)
            .chartYAxisLabel("Weight (kg)", alignment: .center)
            .chartXAxis {
                AxisMarks()
            }
            .chartYAxis {
                AxisMarks()
            }
        }
        .padding()
        .background(Color("AppBackground")) // View background
        .ignoresSafeArea(edges: .bottom)
    }
}
