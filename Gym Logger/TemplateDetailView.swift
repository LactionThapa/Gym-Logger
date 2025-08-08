import SwiftUI

struct TemplateDetailView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @EnvironmentObject var profileManager: UserProfileManager

    let template: WorkoutTemplate
    @State private var exercises: [Exercise]
    @State private var showConfirmation = false
    @FocusState private var focusedField: FocusField?
    @State private var started = false
    
    @State private var showFAB = false
    @State private var showFABButtons = [false, false, false]
    @State private var isCreatingExercise = false
    @State private var selectedExerciseFromLibrary: Exercise? = nil
    
    @AppStorage("restTimerAutoStart") private var autoStartTimer: Bool = true
    @AppStorage("globalRestTime") private var restTime: Int = 30
    @State private var remainingTime: Int = 30
    @State private var isTimerRunning = false
    @State private var restTimer: Timer? = nil
    @State private var showingTimePicker = false

    enum FocusField: Hashable {
            case weight(UUID)
            case reps(UUID)
    }
    
    var isWorkoutComplete: Bool {
        exercises.allSatisfy { exercise in
            exercise.sets.allSatisfy { $0.completedReps != nil }
        }
    }

    init(template: WorkoutTemplate, started: Bool = false) {
        self.template = template
        _exercises = State(initialValue: template.exercises)
        self._started = State(initialValue: started)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                RestTimerView(
                    isRunning: $isTimerRunning,
                    remainingTime: $remainingTime,
                    showingTimePicker: $showingTimePicker,
                    restTime: restTime,
                    onStart: startTimer,
                    onStop: stopTimer
                )
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(exercises.indices, id: \.self) { i in
                                exerciseSection(for: i)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            VStack(alignment: .trailing, spacing: 12) {
                if showFAB {
                    if showFABButtons[0] {
                        Button(action: {
                            if isWorkoutComplete {
                                showConfirmation = true
                            }
                            hideFAB()
                        }) {
                            Label("Log Workout", systemImage: "checkmark.circle")
                                .padding(8)
                                .background(isWorkoutComplete ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .disabled(!isWorkoutComplete)
                    }
                    if showFABButtons[1] {
                        Button(action: {
                            selectedExerciseFromLibrary = Exercise(name: "", weight: 0, sets: [])
                            hideFAB()
                        }) {
                            Label("Import from Library", systemImage: "books.vertical")
                                .padding(8)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if showFABButtons[2] {
                        Button(action: {
                            isCreatingExercise = true
                            hideFAB()
                        }) {
                            Label("New Exercise", systemImage: "square.and.pencil")
                                .padding(8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                Button(action: toggleFAB) {
                    Image(systemName: showFAB ? "xmark" : "plus")
                        .font(.title)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            .padding()
        }

        // Rest of your body: background, toolbar, alert, etc.
        .background(Color("AppBackground"))
        .ignoresSafeArea(.keyboard, edges: [])
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(template.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .alert("Log this workout?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log", role: .destructive) {
                let workout = Workout(exercises: exercises, templateName: template.name)
                workoutStorage.save(workout: workout)
                profileManager.addXP(exercises.count * 10)

                let updatedTemplate = WorkoutTemplate(id: template.id, name: template.name, exercises: exercises)
                templateStorage.updateTemplate(updatedTemplate)

                for ex in exercises {
                    exerciseLibrary.addOrUpdate(ex)
                }

                dismiss()
            }
        }
        .onAppear {
            if started {
                for i in exercises.indices {
                    for j in exercises[i].sets.indices {
                        exercises[i].sets[j].completedReps = nil
                    }
                }
            }
        }
        .sheet(isPresented: $isCreatingExercise) {
            ExerciseEditorView { newExercise in
                var cleanedExercise = newExercise
                for i in cleanedExercise.sets.indices {
                    cleanedExercise.sets[i].completedReps = nil
                }

                exercises.append(cleanedExercise)
                isCreatingExercise = false
            }
        }
        .sheet(item: $selectedExerciseFromLibrary) { _ in
            ExerciseLibraryPickerView(selectedExercises: Binding(
                get: { self.exercises },
                set: { self.exercises = $0.map { exercise in
                    var modified = exercise
                    for i in modified.sets.indices {
                        modified.sets[i].completedReps = nil
                    }
                    return modified
                } }
            ))
            .environmentObject(exerciseLibrary)
        }
        .sheet(isPresented: $showingTimePicker) {
            VStack {
                Text("Select Rest Time")
                    .font(.headline)
                Picker("Rest Time", selection: $restTime) {
                    ForEach(Array(stride(from: 15, through: 300, by: 15)), id: \.self) { value in
                        Text("\(value) seconds").tag(value)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .labelsHidden()
                .frame(height: 150)
                Button("Done") {
                    showingTimePicker = false
                    remainingTime = restTime
                }
                .padding()
            }
            .presentationDetents([.height(300)])
        }
    }


    // ✅ Extracted helper to simplify the body and avoid compiler issues
    private func exerciseSection(for index: Int) -> some View {
        let exercise = exercises[index]

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Menu {
                    Button("Delete", role: .destructive) {
                        exercises.remove(at: index)
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                }
            }
            // Column Headers
            HStack {
                Text("Set").frame(width: 40, alignment: .leading)
                Text("Weight").frame(width: 60, alignment: .leading)
                Text("Reps").frame(width: 60, alignment: .leading)
                Spacer()
                Text("Done")
            }
            .font(.caption)
            .foregroundColor(Color.gray)
            // Set rows
            ForEach(Array(exercises[index].sets.indices), id: \.self) { j in
                let set = exercises[index].sets[j]
                let isDone = set.completedReps != nil

                HStack {
                    Button(action: {
                        exercises[index].sets.remove(at: j)
                    }) {
                        Circle()
                            .strokeBorder(Color(hex: "F9AA33"), lineWidth: 2)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(j + 1)")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "F9AA33"))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    TextField("Weight", value: $exercises[index].weight, format: .number)
                        .keyboardType(.decimalPad)
                        .foregroundColor(isDone ? .gray : .white)
                        .frame(width: 60)
                        .disabled(isDone)
                        .focused($focusedField, equals: .weight(set.id))

                    TextField("Reps", value: $exercises[index].sets[j].targetReps, format: .number)
                        .keyboardType(.numberPad)
                        .foregroundColor(isDone ? .gray : .white)
                        .frame(width: 60)
                        .disabled(isDone)
                        .focused($focusedField, equals: .reps(set.id))

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { isDone },
                        set: { isChecked in
                            exercises[index].sets[j].completedReps = isChecked ? exercises[index].sets[j].targetReps : nil
                            if isChecked && autoStartTimer {
                                startTimer()
                            }
                        }
                    ))
                    .labelsHidden()
                }
            }

            Button(action: {
                exercises[index].sets.append(ExerciseSet(targetReps: 10, completedReps: nil))
            }) {
                Text("Add Set")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "F9AA33"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(hex: "232F34"))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    private func toggleFAB() {
        if showFAB {
            withAnimation {
                showFABButtons = [false, false, false]
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showFAB = false
            }
        } else {
            showFAB = true
            for i in showFABButtons.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showFABButtons[i] = true
                    }
                }
            }
        }
    }

    private func hideFAB() {
        withAnimation {
            showFABButtons = [false, false, false]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showFAB = false
        }
    }
    private func startTimer() {
        isTimerRunning = true
        remainingTime = restTime

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                t.invalidate()
                restTimer = nil
                isTimerRunning = false
                triggerHaptic()
            }
        }
    }

    private func stopTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isTimerRunning = false
        remainingTime = restTime
    }

    private func triggerHaptic() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

}
