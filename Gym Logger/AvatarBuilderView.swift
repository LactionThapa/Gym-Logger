import SwiftUI
let HAIR_ITEMS    = ["Hair1","Hair11","Hair12", "Hair13","Hair2","Hair3","Hair4","Hairm1","Hairm2","Hairm4","Hsirb"]
let TOP_ITEMS     = ["Jumper1","Jumper2", "Jumper4", "Pink","BLUE SHIRT", "Green shirt"]
let BOTTOM_ITEMS  = ["Illustration2", "Short1", "Shorts2"]
let ACCESS_ITEMS  = ["Pink party glasses", "Sunglasses"] // add when you have them

struct AvatarBuilderView: View {
    @State private var loadout = AvatarLoadout()
    @State private var showingCategory: AvatarCategory? = nil

    var body: some View {
        ZStack {
            loadout.background.ignoresSafeArea()

            HStack(spacing: 16) {

                // LEFT: Category grid (like picture #1)
                CategoryList(selected: showingCategory, onTap: { cat in
                    showingCategory = cat
                })
                .frame(width: 80)        // optional; keeps a neat column

                // RIGHT: Live preview
                AvatarPreview(loadout: loadout)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.15))
                    )
                    .overlay(alignment: .topTrailing) {
                        Menu {
                            Button("Teal",   action: { loadout.background = Color(hex: "0E808C") })
                            Button("Purple", action: { loadout.background = Color(hex: "462E6A") })
                            Button("Charcoal", action: { loadout.background = Color(hex: "0E1C26") })
                            Button("Gradient") {
                                loadout.background = Color.clear // we’ll overlay below
                            }
                        } label: {
                            Image(systemName: "paintpalette.fill")
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding(12)
                    }
                    .background(
                        // optional gradient layer when background == .clear
                        LinearGradient(colors: [.blue.opacity(0.35), .purple.opacity(0.35)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding()
        }
        // BOTTOM SHEET that looks like picture #2
        .sheet(item: $showingCategory) { cat in
            ItemPickerSheet(
                category: cat,
                selected: binding(for: cat),
                items: items(for: cat)
            )
            .presentationDetents([.fraction(0.27)])
            .presentationDragIndicator(.visible)
            .background(Color("AppBackground"))
        }
    }

    // Map category -> items
    private func items(for cat: AvatarCategory) -> [String] {
        switch cat {
        case .hair: return HAIR_ITEMS
        case .accessories: return ACCESS_ITEMS
        case .tops: return TOP_ITEMS
        case .bottoms: return BOTTOM_ITEMS
        
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
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.1)).frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            HStack {
                Text(category.title)
                    .font(.headline).foregroundColor(.white)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NoneTile(isSelected: selected == nil) { selected = nil }

                    ForEach(items, id: \.self) { name in
                        ItemTile(
                            imageName: name,
                            isSelected: selected == name
                        ) {
                            selected = name
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .padding(.top, 33)
        .background(Color.black.opacity(0.50))
    }
}

struct ItemTile: View {
    let imageName: String
    let isSelected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18) // a bit rounder
                    .fill(Color.white.opacity(0.06))
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(12) // slightly more padding
            }
            .frame(width: 136, height: 136) // bigger tile
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(hex: "F9AA33") : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
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


#Preview{
    AvatarBuilderView2()
}

