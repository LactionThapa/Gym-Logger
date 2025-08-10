import SwiftUI

struct AvatarBuilderView: View {
    @State private var loadout = AvatarLoadout()
    @State private var showingCategory: AvatarCategory? = nil
    @StateObject private var avatarManager = AvatarManager()
    @EnvironmentObject var profileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    
    
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                loadout.background.ignoresSafeArea()
                
                HStack(spacing: 16) {
                    CategoryList(selected: showingCategory) { cat in
                        showingCategory = cat
                    }
                    .frame(width: 80)
                    
                    AvatarPreview(loadout: loadout)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.black.opacity(0.15))
                        )
                        .background(
                            LinearGradient(colors: [.blue.opacity(0.35), .purple.opacity(0.35)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                }
                .padding()
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // Back (top-left)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(hex:"F9AA33"))
                            Text("Back")
                                .foregroundColor(Color(hex:"F9AA33"))
                        }
                    }
                }
                // Save (top-right)
                ToolbarItem(placement: .topBarTrailing) {
                    if authManager.isAnonymous {
                        Button {
                            showLogin = true
                        } label: {
                            HStack{
                                Image(systemName: "person.badge.key")
                                    .foregroundColor(Color(hex: "F9AA33"))
                                Text("Sign In")
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("Sign in to save your avatar")
                    } else {
                        Button {
                            avatarManager.saveAvatar(loadout) { error in
                                if let error = error {
                                    print("❌ Failed to save avatar:", error.localizedDescription)
                                } else {
                                    print("✅ Avatar saved!")
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Save").fontWeight(.semibold)
                                .foregroundColor(Color(hex:"F9AA33"))
                        }
                    }
                }
            }
            // Sheet stays the same
            .sheet(item: $showingCategory) { cat in
                ItemPickerSheet(
                    category: cat,
                    selected: binding(for: cat),
                    items: items(for: cat),
                    userLevel: profileManager.profile.level // <-- from env object
                )
                .presentationDetents([.fraction(0.27)])
                .presentationDragIndicator(.visible)
                .background(Color("AppBackground"))
            }
            .sheet(isPresented: $showLogin) {LoginView()}
            .onAppear {
                if !authManager.isAnonymous {
                    avatarManager.loadAvatar { result in
                        if case .success(let saved) = result { self.loadout = saved }
                    }
                }
            }
        }
    }
    
    private func items(for cat: AvatarCategory) -> [AvatarItem] {
        switch cat {
        case .hair:       return HAIR_ITEMS
        case .tops:       return TOP_ITEMS
        case .bottoms:    return BOTTOM_ITEMS
        case .accessories:return ACCESS_ITEMS
        }
    }

    
    // Map category -> binding into loadout
    private func binding(for cat: AvatarCategory) -> Binding<String?> {
        switch cat {
        case .hair:       return $loadout.hair
        case .tops:       return $loadout.top
        case .bottoms:    return $loadout.bottom
        case .accessories:return $loadout.accessory
        }
    }
}
struct CategoryList: View {
    var selected: AvatarCategory?
    var onTap: (AvatarCategory) -> Void
    
    var body: some View {
        // no background, no rounded rect — just a vertical stack
        VStack(spacing: 14) {
            ForEach(AvatarCategory.allCases) { cat in
                CategoryTile(
                    cat: cat,
                    isSelected: cat == selected,
                    onTap: { onTap(cat) }
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 6)        // a little breathing room from the edge
        .background(Color.clear)     // <- invisible rail
    }
}


private struct CategoryTile: View {
    let cat: AvatarCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(cat.title)
                    .font(.caption2).bold()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.white.opacity(0.95))
            .frame(width: 72, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)     // glassy tile like GO
                    .opacity(0.55)                 // feels “floating”
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.12),
                            lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.45 : 0.25),
                    radius: isSelected ? 10 : 6, y: 3)
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14)) // nice hit area
    }
}



struct AvatarPreview: View {
    let loadout: AvatarLoadout
    
    var body: some View {
        ZStack {
            // base body
            Image(loadout.baseBody)
                .resizable()
                .scaledToFit()
            
            // bottoms under tops (if your art is drawn that way)
            if let bottom = loadout.bottom {
                Image(bottom)
                    .resizable()
                    .scaledToFit()
            }
            
            if let top = loadout.top {
                Image(top)
                    .resizable()
                    .scaledToFit()
            }
            
            if let hair = loadout.hair {
                Image(hair)
                    .resizable()
                    .scaledToFit()
            }
            
            if let acc = loadout.accessory {
                Image(acc)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
struct ItemPickerSheet: View {
    let category: AvatarCategory
    @Binding var selected: String?
    let items: [AvatarItem]
    let userLevel: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            HStack {
                Text(category.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NoneTile(isSelected: selected == nil) { selected = nil }

                    ForEach(items) { item in
                        tile(for: item)   // <— simplified call
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .padding(.top, 33)
        .background(Color.black.opacity(0.50))
    }

    @ViewBuilder
    private func tile(for item: AvatarItem) -> some View {
        let isLocked = userLevel < item.requiredLevel
        ItemTile(
            imageName: item.name,
            isSelected: selected == item.name,
            isLocked: isLocked,
            requiredLevel: item.requiredLevel,   // <— pass this
            tap: {
                if !isLocked { selected = item.name }
            }
        )
    }
}




struct ItemTile: View {
    let imageName: String
    let isSelected: Bool
    let isLocked: Bool
    let requiredLevel: Int
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .opacity(isLocked ? 0.35 : 1.0)

                if isLocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Label("Lvl \(requiredLevel)", systemImage: "lock.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.65))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(8)
                        }
                    }
                }
            }
            .frame(width: 136, height: 136)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(hex: "F9AA33") : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}


struct NoneTile: View {
    let isSelected: Bool
    let tap: () -> Void
    
    var body: some View {
        Button(action: tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                VStack(spacing: 8) {
                    Image(systemName: "nosign")
                        .font(.title)
                    Text("None").font(.caption)
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 136, height: 136) // match size with ItemTile
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(hex: "F9AA33") : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}
