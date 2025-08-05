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
                            VStack{
                                HStack{
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    Button {
                                        editingTemplate = template
                                        isEditingActive = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color(hex: "4A6572"))
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 4)
                                    
                                    Button(role: .destructive) {
                                        templateStorage.deleteTemplate(id: template.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .padding(8)
                                            .background(Color(hex: "4A6572"))
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                NavigationLink(destination: TemplateDetailView(template: template)) {
                                    VStack(alignment: .leading) {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(template.exercises, id: \.id) { exercise in
                                                    Text(exercise.name)
                                                        .font(.caption)
                                                        .padding(.vertical, 4)
                                                        .padding(.horizontal, 8)
                                                        .background(Color(hex: "F9AA33"))
                                                        .foregroundColor(.black)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "232F34").opacity(1)) // or any light/dark adaptive color
                                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4) // shadow for floating
                            )
                            .padding(.horizontal, 8)
                        }
                        
                    }
                    .padding()
                }
                
                NavigationLink(destination: WorkoutBuilderView()) {
                    Label("Create Template", systemImage: "plus")
                        .padding()
                        .background(Color(hex: "F9AA33"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Workouts")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            .background(Color("AppBackground").ignoresSafeArea())
            
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

