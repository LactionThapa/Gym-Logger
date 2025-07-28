import SwiftUI

struct TemplateManagerView: View {
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(templateStorage.templates) { template in
                Button(template.name) {
                    selectedExercises = template.exercises
                    dismiss()
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let id = templateStorage.templates[index].id
                    templateStorage.deleteTemplate(id: id)
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
}
