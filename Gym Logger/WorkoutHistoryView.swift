import SwiftUI

struct IdentifiableString: Identifiable, Equatable {
    var id: String { value }
    let value: String
}

struct WorkoutHistoryView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    @State private var expandedWorkouts: Set<UUID> = []
    @State private var selectedExerciseName: IdentifiableString? = nil

    var filteredWorkouts: [Workout] {
        guard !searchText.isEmpty else { return workoutStorage.history }
        return workoutStorage.history.compactMap { workout in
            let filteredExercises = workout.exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            if !filteredExercises.isEmpty {
                var w = workout
                w.exercises = filteredExercises
                return w
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredWorkouts) { workout in
                        workoutCard(for: workout)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color("AppBackground"))
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: String.self) { exerciseName in
                ProgressChartView(exerciseName: exerciseName, history: workoutStorage.history)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Spacer()
                        Text("Workout Logs")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            .onAppear {
                if authManager.isLoggedIn {
                    workoutStorage.load()
                }
            }
            .onChange(of: authManager.user) { _ in
                if authManager.isAnonymous {
                    workoutStorage.reset()
                } else {
                    workoutStorage.load()
                }
            }
            .onAppear {
                configureSearchBarAppearance()
            }
            .sheet(item: $selectedExerciseName) { identifiable in
                CompactProgressChart(exerciseName: identifiable.value, history: workoutStorage.history)
                    .presentationDetents([.height(360)]) // Optional: control the popup height
                    .presentationDragIndicator(.visible)
            }
        }
        
    }

    // MARK: - Card View for Each Workout
    private func workoutCard(for workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.templateName) // Template name
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: {
                    if expandedWorkouts.contains(workout.id) {
                        expandedWorkouts.remove(workout.id)
                    } else {
                        expandedWorkouts.insert(workout.id)
                    }
                }) {
                    Image(systemName: expandedWorkouts.contains(workout.id) ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .padding(8)
                }
            }

            if expandedWorkouts.contains(workout.id) {
                ForEach(workout.exercises) { ex in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ex.name).bold().foregroundColor(.white)
                        Text("Weight: \(ex.weight, specifier: "%.1f") kg")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Reps: \(ex.sets.map { $0.completedReps.map(String.init) ?? "-" }.joined(separator: ", "))")
                            .foregroundColor(.white.opacity(0.8))

                        Button(action: {
                            selectedExerciseName = IdentifiableString(value: ex.name)
                        }) {
                            Text("View Progress")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(hex: "232F34"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
    }

}

import Charts
import SwiftUI

struct CompactProgressChart: View {
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
                        result.append(ChartPoint(date: workout.date, weight: exercise.weight))
                    }
                }
            }
        }
        return result.sorted { $0.date < $1.date }
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
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .border(Color.white.opacity(0.2), width: 1)
                }
                .chartXAxis { AxisMarks() }
                .chartYAxis { AxisMarks() }
                .frame(height: 300)

                // ✅ Overlay Y-axis label on the right
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
