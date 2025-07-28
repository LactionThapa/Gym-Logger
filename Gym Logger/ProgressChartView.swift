import SwiftUI
import Charts

struct ProgressChartView: View {
    let exerciseName: String
    let history: [Workout]

    var dataPoints: [(date: Date, weight: Double, estimated1RM: Double)] {
        history
            .flatMap { workout in
                workout.exercises
                    .filter { $0.name == exerciseName }
                    .flatMap { ex in
                        ex.sets.compactMap { set in
                            guard let reps = set.completedReps, reps > 0,
                                  let weight = set.weight else { return nil }
                            let oneRM = estimateOneRepMax(weight: weight, reps: reps)
                            return (date: workout.date, weight: weight, estimated1RM: oneRM)
                        }
                    }
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Progress for \(exerciseName)")
                .font(.headline)

            Chart {
                ForEach(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.estimated1RM)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .frame(height: 300)
        }
        .padding()
    }
}
