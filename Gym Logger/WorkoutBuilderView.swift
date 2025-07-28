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
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @State private var showingLibraryPicker = false


    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section(header: Text("Template Name")) {
                        TextField("Name", text: $name)
                    }

                    Section(header: Text("Exercises")) {
                        ForEach(Array(currentExercises.enumerated()), id: \.element.id) { index, exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.name).bold()
                                Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
                                     Text("Target Reps: \(exercise.sets.map { String($0.targetReps) }.joined(separator: ", "))")
                            }
                            .onTapGesture {
                                selectedExercise = IdentifiableExercise(exercise: exercise)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                currentExercises.remove(at: index)
                            }
                        }
                    }
                }

                VStack(alignment: .trailing, spacing: 12) {
                    Button(action: {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
                                  !currentExercises.isEmpty else {
                                return // Prevent save if name or exercises are empty
                        }
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

                        dismiss()
                    }) {
                        Label("Save Template", systemImage: "square.and.arrow.down")
                            .padding(8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || currentExercises.isEmpty)
                    Button(action: {
                        selectedExercise = nil
                        isCreatingNewExercise = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    Button(action: {
                        showingLibraryPicker = true
                    }){
                        Label("Import from library", systemImage: "books.vertical")
                            .padding(8)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                        
                    .sheet(isPresented: $showingLibraryPicker) {
                        ExerciseLibraryPickerView(selectedExercises: $currentExercises)
                            .environmentObject(exerciseLibrary)
                    }
                }

                .padding()
            }
            .navigationTitle(templateToEdit != nil ? "Edit Workout" : "Build Workout")
            .toolbar {
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
            .onAppear {
                if let t = templateToEdit {
                    name = t.name
                    currentExercises = t.exercises
                }
            }
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
                        Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
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

