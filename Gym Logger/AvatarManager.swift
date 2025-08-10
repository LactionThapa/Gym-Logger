import FirebaseAuth
import FirebaseFirestore

class AvatarManager {
    private let db = Firestore.firestore()

    func saveAvatar(_ loadout: AvatarLoadout, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }

        do {
            let data = try JSONEncoder().encode(loadout)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            db.collection("users").document(uid).setData(["avatarLoadout": dict], merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    func loadAvatar(completion: @escaping (Result<AvatarLoadout, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data()?["avatarLoadout"] as? [String: Any] else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "No avatar found"])))
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let loadout = try JSONDecoder().decode(AvatarLoadout.self, from: jsonData)
                completion(.success(loadout))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
