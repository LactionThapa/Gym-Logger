    import SwiftUI

    struct TemplateListView: View {
        @EnvironmentObject var templateStorage: WorkoutTemplateStorage
        @EnvironmentObject var workoutStorage: WorkoutStorage
        @EnvironmentObject var profileManager: UserProfileManager
        @EnvironmentObject var authManager: AuthManager

        @State private var editingTemplate: WorkoutTemplate? = nil
        @State private var isEditingActive: Bool = false
        @State private var templateToDelete: WorkoutTemplate?
        @State private var showDeleteConfirmation = false
        @State private var selectedTemplateForDetail: WorkoutTemplate? = nil
        @State private var showDetail: Bool = false

        var body: some View {
            NavigationStack {
                VStack {
                    Divider()
                        .frame(height: 5)
                        .background(Color(hex: "344955"))
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 1)
                    templateList
                    createTemplateButton
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Workouts")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .shadow(color: .orange, radius: 4)
                                Text("\(profileManager.profile.currentStreak)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(6)
                            .background(Color(hex: "#4A6572"))
                            .clipShape(Capsule())
                        }
                }
                .background(Color("AppBackground").ignoresSafeArea())
                .navigationDestination(isPresented: $isEditingActive) { editDestination }
                .navigationDestination(isPresented: $showDetail) { detailDestination }
                .onAppear(perform: handleAppear)
                .onChange(of: authManager.user, handleUserChange)
                .alert("Delete Template", isPresented: $showDeleteConfirmation, presenting: templateToDelete, actions: deleteAlertActions, message: deleteAlertMessage)
            }
        }

        private var templateList: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(templateStorage.templates) { template in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                editingTemplate = template
                                isEditingActive = true
                            }
                        } label: {
                            TemplateCardView(
                                template: template,
                                onEdit: {
                                    editingTemplate = template
                                    isEditingActive = true
                                },
                                onDelete: {
                                    templateToDelete = template
                                    showDeleteConfirmation = true
                                },
                                onTap:{
                                    selectedTemplateForDetail = template
                                    showDetail = true
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .id(template.id)
                    }
                }
                .padding()
            }
        }

        private var createTemplateButton: some View {
            BounceNavigationButton(
                label: {
                    Label("Create Workout", systemImage: "plus")
                        .padding()
                        .background(Color(hex: "F9AA33"))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                },
                destination: WorkoutBuilderView()
            )
            .padding()
        }

        @ViewBuilder
        private var editDestination: some View {
            if let template = editingTemplate {
                WorkoutBuilderView(templateToEdit: template)
            }
        }
        @ViewBuilder
        private var detailDestination: some View {
            if let template = selectedTemplateForDetail {
                TemplateDetailView(template: template, started: true)
            }
        }

        private func handleAppear() {
            if authManager.isLoggedIn {
                templateStorage.fetchTemplates()
                templateStorage.seedDefaultsOncePerUser()
            }
            if authManager.isAnonymous{
                templateStorage.seedDefaultsOncePerUser()
            }
        }

        private func handleUserChange() {
            if authManager.isAnonymous {
                templateStorage.reset()
            } else {
                templateStorage.fetchTemplates()
            }
        }

        private func deleteAlertActions(template: WorkoutTemplate) -> some View {
            Group {
                Button("Delete", role: .destructive) {
                    templateStorage.deleteTemplate(id: template.id)
                }
                Button("Cancel", role: .cancel) {}
            }
        }

        private func deleteAlertMessage(template: WorkoutTemplate) -> Text {
            Text("Are you sure you want to delete \"\(template.name)\"?")
        }

    }


    // MARK: - Template Card View

    struct TemplateCardView: View {
        let template: WorkoutTemplate
        let onEdit: () -> Void
        let onDelete: () -> Void
        let onTap: () -> Void

        @State private var isPressed = false

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                TemplateCardHeader(template: template, onEdit: onEdit, onDelete: onDelete)
                ExerciseListScrollView(exercises: template.exercises)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "232F34"))
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .onTapGesture {
                // Animate press effect
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }


    // MARK: - Template Card Header

    struct TemplateCardHeader: View {
        let template: WorkoutTemplate
        let onEdit: () -> Void
        let onDelete: () -> Void
        
        @State private var isEditPressed = false
        @State private var isDeletePressed = false
        
        var body: some View {
            HStack {
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                                isEditPressed = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isEditPressed = false
                                    onEdit()
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color(hex: "4A6572"))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .scaleEffect(isEditPressed ? 0.9 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isEditPressed)
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)

                Button(action: {
                                isDeletePressed = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isDeletePressed = false
                                    onDelete()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color(hex: "4A6572"))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .scaleEffect(isDeletePressed ? 0.9 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isDeletePressed)
                            .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Horizontal Scroll of Exercises

    struct ExerciseListScrollView: View {
        let exercises: [Exercise]

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(exercises, id: \.id) { exercise in
                        ExercisePillView(exercise: exercise)
                    }
                }
            }
        }
    }

    // MARK: - Exercise Pill View

    struct ExercisePillView: View {
        let exercise: Exercise

        var body: some View {
            Text(exercise.name)
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(hex: "F9AA33"))
                .foregroundColor(.black)
                .clipShape(Capsule())
        }
    }

    // MARK: - Bunce Navigation View
    struct BounceNavigationButton<Label: View, Destination: View>: View {
        @State private var isPressed = false
        @State private var navigate = false

        let label: () -> Label
        let destination: Destination

        var body: some View {
            ZStack {
                NavigationLink(destination: destination, isActive: $navigate) {
                    EmptyView()
                }
                .hidden()
                Button(action: {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                        navigate = true
                    }
                }) {
                    label()
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
                }
                .buttonStyle(.plain)
            }
        }
    }
