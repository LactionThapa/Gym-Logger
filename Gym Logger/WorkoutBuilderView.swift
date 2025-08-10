import SwiftUI

struct IdentifiableExercise: Identifiable, Equatable {
    let exercise: Exercise

    var id: UUID { exercise.id }

    static func == (lhs: IdentifiableExercise, rhs: IdentifiableExercise) -> Bool {
        lhs.exercise.id == rhs.exercise.id
    }
}


struct WorkoutBuilderView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @Environment(\.dismiss) var dismiss

    var templateToEdit: WorkoutTemplate? = nil

    @State private var name: String = ""
    @State private var currentExercises: [Exercise] = []
    @State private var showingExecution = false
    @State private var showingTemplatePicker = false
    @State private var showingTemplateNamePrompt = false
    @State private var newTemplateName: String = ""
    @State private var selectedExercise: IdentifiableExercise?
    @State private var isCreatingNewExercise = false
    @State private var showingLibraryPicker = false
    @State private var showActionMenu = false
    @State private var showMenuButtons: [Bool] = [false, false, false]
    @State private var showUnsavedAlert = false
    @State private var shouldDismiss = false
    @State private var showIncompleteAlert = false
    @State private var showGoBackAlert = false
    

    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section(header: Text("Template Name")) {
                        TextField("Name", text: $name)
                            //.foregroundColor(.black)
                    }

                    Section(header: Text("Exercises")) {
                        ForEach(Array(currentExercises.enumerated()), id: \.element.id) { index, exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))

                                Text("Target Reps: \(exercise.sets.map { String($0.targetReps) }.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "232F34"))
                                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                            )
                            .onTapGesture {
                                selectedExercise = IdentifiableExercise(exercise: exercise)
                            }
                            .listRowBackground(Color.clear) // ✅ Removes default white background
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 6)

                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                currentExercises.remove(at: index)
                            }
                        }
                    }
                    .foregroundColor(.white)
                }
                .scrollContentBackground(.hidden)
                .background(Color("AppBackground"))
                VStack(alignment: .trailing, spacing: 12) {
                    if showActionMenu {
                        Group {
                            if showMenuButtons[0] {
                                Button(action: {
                                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                        currentExercises.isEmpty {
                                        showIncompleteAlert = true
                                    } else {
                                        saveWorkout()
                                        dismiss()
                                    }
                                    resetFab()
                                }) {
                                    Label("Save Workout", systemImage: "checkmark.circle")
                                        .padding(8)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            if showMenuButtons[1] {
                                Button(action: {
                                    showingLibraryPicker = true
                                    showActionMenu = false
                                    showMenuButtons = [false, false]
                                    resetFab()
                                }) {
                                    Label("Import from Library", systemImage: "books.vertical")
                                        .padding(8)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            if showMenuButtons[2] {
                                Button(action: {
                                    selectedExercise = nil
                                    isCreatingNewExercise = true
                                    showActionMenu = false
                                    showMenuButtons = [false, false]
                                    resetFab()
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
                    }


                        // Main FAB button
                    Button(action: {
                        if showActionMenu {
                            // Hide all buttons instantly
                            withAnimation {
                                showMenuButtons = [false, false, false]
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showActionMenu = false
                            }
                        } else {
                            showActionMenu = true
                            for index in showMenuButtons.indices {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showMenuButtons[index] = true
                                    }
                                }
                            }
                        }
                    }) {
                        Image(systemName: showActionMenu ? "xmark" : "plus")
                            .font(.title)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }

                    }
                    .padding()
                    //.animation(.spring(response: 0.8, dampingFraction: 0.7), value: showActionMenu)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .alert("Workout won't be saved", isPresented: $showUnsavedAlert) {
                Button("Cancel", role: .cancel) {}
                Button("OK", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your workout is incomplete. You have missing fields. Are you sure you want to go back?")
            }
            .alert("Save Workout", isPresented: $showGoBackAlert) {
                Button("Save") {
                        saveWorkout()
                        dismiss()
                    }
                    Button("Go Back", role: .destructive) {
                        dismiss()
                    }
            } message: {
                Text("Do you want to save your workout?")
            }
            
            .alert("Missing Fields", isPresented: $showIncompleteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a workout name and add at least one exercise before saving.")
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(templateToEdit != nil ? "Edit Workout" : "Build Workout")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && currentExercises.isEmpty {
                            dismiss()
                        } else if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || currentExercises.isEmpty{
                            showUnsavedAlert = true
                        }else {
                            showGoBackAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color(hex:"F9AA33"))
                    }
                }

                // Keep your existing title toolbar item here
                ToolbarItem(placement: .principal) {
                    Text(templateToEdit != nil ? "Edit Workout" : "Build Workout")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }

            .sheet(item: $selectedExercise) { wrapper in
                ExerciseEditorView(exerciseToEdit: wrapper.exercise) { editedExercise in
                    if let index = currentExercises.firstIndex(where: { $0.id == wrapper.exercise.id }) {
                        currentExercises[index] = editedExercise
                    } else {
                        currentExercises.append(editedExercise)
                    }
                }
            }
            .sheet(isPresented: $isCreatingNewExercise) {
                ExerciseEditorView(exerciseToEdit: nil) { newExercise in
                    currentExercises.append(newExercise)
                    isCreatingNewExercise = false
                }
            }

            .sheet(isPresented: $showingTemplatePicker) {
                NavigationStack {
                    TemplateManagerView(selectedExercises: $currentExercises)
                        .environmentObject(templateStorage)
                }
            }
            .sheet(isPresented: $showingLibraryPicker) {
                ExerciseLibraryPickerView(selectedExercises: $currentExercises)
                    .environmentObject(exerciseLibrary)
            }
            .onAppear {
                if let t = templateToEdit {
                    name = t.name
                    currentExercises = t.exercises
                }
            }
        }
    }
    private func saveWorkout() {
        let template = WorkoutTemplate(
            id: templateToEdit?.id ?? UUID(),
            name: name,
            exercises: currentExercises
        )

        if templateToEdit != nil {
            templateStorage.updateTemplate(template)
        } else {
            templateStorage.saveTemplate(template)
        }
    }
    private func resetFab() {
        withAnimation {
            showMenuButtons = [false, false, false]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showActionMenu = false
        }
    }

}
struct ExerciseLibraryView: View {
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    var onSelect: (Exercise) -> Void

    var body: some View {
        List {
            ForEach(exerciseLibrary.savedExercises) { exercise in
                Button(action: {
                    onSelect(exercise)
                }) {
                    VStack(alignment: .leading) {
                        Text(exercise.name).bold()
                        //Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
                        Text("Target Reps: \(exercise.sets.map { "\($0.targetReps)" }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Exercise Library")
    }
}

