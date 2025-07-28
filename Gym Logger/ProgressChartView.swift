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
                    if let reps = set.completedReps, reps > 0 {let weight = exercise.weight
                        result.append(ChartPoint(date: workout.date, weight: weight))
                    }
                }
            }
        }

        return result.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Progress for \(exerciseName)")
                .font(.headline)

            Chart(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 300)
        }
        .padding()
    }
}
