import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class WorkoutTemplateStorage: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []
    
    private let key = "WorkoutTemplates"
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        signInIfNeeded()
        loadFromLocal()
        listenToRemoteChanges()
    }
    deinit{
        listener?.remove()
    }
    
    func seedDefaultsOncePerUser() {
            guard let uid = Auth.auth().currentUser?.uid else { return }

            let userDocRef = db.collection("users").document(uid)

            userDocRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("⚠️ Error checking seed flag: \(error)")
                    return
                }

                let alreadySeeded = snapshot?.data()?["didSeedTemplates"] as? Bool ?? false

                if alreadySeeded {
                    print("ℹ️ Templates already seeded for this user.")
                    return
                }

                // Seed defaults
                let defaults = WorkoutTemplate.defaultTemplates()
                defaults.forEach { self.saveTemplate($0) }

                // Update flag
                userDocRef.setData(["didSeedTemplates": true], merge: true)
                print("✅ Default templates seeded & flag set.")
            }
        }
    
    func saveTemplate(_ template: WorkoutTemplate) {
        templates.append(template)
        persistLocally()
        uploadTemplate(template)
    }
    
    
    func replaceTemplate(id: UUID, with updated: WorkoutTemplate) {
        updateTemplate(updated)
    }
    
    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        persistLocally()
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid)
            .collection("templates").document(id.uuidString)
            .delete()
    }
    
    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func updateTemplate(_ updated: WorkoutTemplate) {
        if let index = templates.firstIndex(where: { $0.id == updated.id }) {
            templates[index] = updated
            persistLocally()
            uploadTemplate(updated)
        }
    }
    private func persistLocally() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadFromLocal() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            self.templates = decoded
        }
    }
    
    // MARK: - Firebase Sync
    private func uploadTemplate(_ template: WorkoutTemplate) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let dict = template.toDictionary()
        db.collection("users")
            .document(uid)
            .collection("templates")
            .document(template.id.uuidString)
            .setData(dict)
    }
    
    private func listenToRemoteChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users")
            .document(uid)
            .collection("templates")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else { return }
                
                let loaded: [WorkoutTemplate] = docs.compactMap { doc in
                    return WorkoutTemplate.fromDictionary(doc.data())
                }
                
                DispatchQueue.main.async {
                    self.templates = loaded
                    self.persistLocally()
                }
            }
    }
    func fetchTemplates() {
            guard let uid = Auth.auth().currentUser?.uid else { return }

            db.collection("users")
                .document(uid)
                .collection("templates")
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Failed to fetch templates: \(error)")
                        return
                    }

                    self.templates = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: WorkoutTemplate.self)
                    } ?? []
                }
    }
    func reset() {
        self.templates = []
    }
    
}
