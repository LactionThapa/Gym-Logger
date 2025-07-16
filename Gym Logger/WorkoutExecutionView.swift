import SwiftUI

struct WorkoutExecutionView: View {
    @Binding var exercises: [Exercise]

    var body: some View {
        List {
            ForEach($exercises) { $exercise in
                Section(header: Text(exercise.name)) {
                    ForEach($exercise.sets) { $set in
                        HStack {
                            Text("Target: \(set.targetReps)")
                            Spacer()
                            TextField("Completed", value: $set.completedReps, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                        }
                    }
                }
            }
        }
        .navigationTitle("Log Completed Reps")
    }
}