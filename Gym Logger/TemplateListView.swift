import SwiftUI

struct TemplateListView: View {
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var editingTemplate: WorkoutTemplate? = nil
    @State private var isEditingActive: Bool = false
    
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
                            .contextMenu {
                                Button("Edit") {
                                    editingTemplate = template
                                    isEditingActive = true
                                }
                                Button("Delete", role: .destructive) {
                                    templateStorage.deleteTemplate(id: template.id)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                NavigationLink(destination: WorkoutBuilderView()) {
                    Label("Create Template", systemImage: "plus")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()
            }
            .navigationTitle("Workout Templates")
            
            // ✅ Modern way to handle navigation using .navigationDestination
            .navigationDestination(isPresented: $isEditingActive) {
                if let template = editingTemplate {
                    WorkoutBuilderView(templateToEdit: template)
                }
            }
            .onAppear {
                if authManager.isLoggedIn {
                    templateStorage.fetchTemplates()
                }
            }
            .onChange(of: authManager.user) { _ in
                if authManager.isAnonymous {
                    templateStorage.reset()
                } else {
                    templateStorage.fetchTemplates()
                }
            }
        }
    }
}



