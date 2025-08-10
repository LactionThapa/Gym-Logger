import FirebaseAuth
import FirebaseFirestore
import SwiftUI

final class AvatarManager: ObservableObject {
    private let db = Firestore.firestore()

    func saveAvatar(_ loadout: AvatarLoadout, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(NSError(domain: "", code: 401,
              userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
        }
        do {
            let dict = try Firestore.Encoder().encode(loadout)
            db.collection("users").document(uid)
              .setData(["avatarLoadout": dict], merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    func loadAvatar(completion: @escaping (Result<AvatarLoadout, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(.failure(NSError(domain: "", code: 401,
              userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
        }
        db.collection("users").document(uid).getDocument { snap, err in
            if let err = err { return completion(.failure(err)) }
            guard let map = snap?.data()?["avatarLoadout"] as? [String: Any] else {
                return completion(.success(AvatarLoadout())) // default if none yet
            }
            do {
                let loadout = try Firestore.Decoder().decode(AvatarLoadout.self, from: map)
                completion(.success(loadout))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
