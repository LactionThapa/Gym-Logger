import Foundation
import Combine

class WorkoutTemplateStorage: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    private let key = "WorkoutTemplates"

    init() {
        loadTemplates()
    }

    func saveTemplate(_ template: WorkoutTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func replaceTemplate(id: UUID, with updated: WorkoutTemplate) {
        if let index = templates.firstIndex(where: { $0.id == id }) {
            templates[index] = updated
            saveTemplates()
        }
    }

    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            templates = decoded
        }
    }
}
