import SwiftUI

struct TemplateListView: View {
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @EnvironmentObject var xpManager: XPManager
    @EnvironmentObject var workoutStorage: WorkoutStorage

    @State private var showingEditor = false
    @State private var selectedTemplate: WorkoutTemplate? = nil

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(templateStorage.templates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Exercises: \(template.exercises.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }

                Button(action: {
                    showingEditor = true
                }) {
                    Label("Create Template", systemImage: "plus")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()
            }
            .navigationTitle("Workout Templates")
            .sheet(isPresented: $showingEditor) {
                WorkoutBuilderView()
            }
        }
    }
}

struct TemplateDetailView: View {
    @EnvironmentObject var xpManager: XPManager
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @Environment(\.dismiss) var dismiss

    let template: WorkoutTemplate
    @State private var exercises: [Exercise]
    @State private var started = false

    init(template: WorkoutTemplate) {
        self.template = template
        _exercises = State(initialValue: template.exercises)
    }

    var body: some View {
        List {
            ForEach(exercises.indices, id: \ .self) { i in
                Section(header: Text(exercises[i].name)) {
                    ForEach(exercises[i].sets.indices, id: \ .self) { j in
                        HStack {
                            Text("Set \(j + 1): Target \(exercises[i].sets[j].targetReps) reps")
                            Spacer()
                            if started {
                                TextField("Done", value: $exercises[i].sets[j].completedReps, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text("Not Started")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button("Start") {
                        started = true
                    }
                    Spacer()
                    Button("Log") {
                        let workout = Workout(exercises: exercises)
                        workoutStorage.save(workout: workout)
                        xpManager.addXP(exercises.count * 10)
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
}