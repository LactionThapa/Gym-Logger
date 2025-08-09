import SwiftUI

struct WorkoutSummaryCard: View {
    let summary: WorkoutSummary
    let onClose: () -> Void

    private let cardBG = Color(hex: "232F34")           // your card color
    private let accent = Color(hex: "F9AA33")           // your accent

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(summary.templateName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.black.opacity(0.85))
                    Text("\(summary.totalXP)")
                        .font(.headline).bold()
                        .foregroundColor(.black.opacity(0.85))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accent, in: Capsule())
                .shadow(color: accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Body (scrollable list)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(summary.exercises) { ex in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(ex.name)
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                                Text("+\(ex.totalXP) XP")
                                    .font(.subheadline).bold()
                                    .foregroundColor(accent)
                            }
                            if ex.weight > 0 {
                                Text("Weight: \(ex.weight, specifier: "%.1f")")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            ForEach(ex.sets) { s in
                                HStack {
                                    Text("Set \(s.index)")
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer()
                                    Text("\(s.completed)/\(s.target) reps")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption)
                                    Text("+\(s.xp) XP")
                                        .font(.caption).bold()
                                        .foregroundColor(accent)
                                        .padding(.leading, 8)
                                }
                                .font(.caption)
                            }

                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 300)

            // Footer
            HStack {
                Text("Total XP Earned")
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                Spacer()
                Text("\(summary.totalXP)")
                    .font(.subheadline).bold()
                    .foregroundColor(accent)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        // Floating round X button in accent, hanging below the card
        .overlay(alignment: .bottom) {
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(cardBG) // contrast against accent
                    .frame(width: 52, height: 52)
                    .background(accent, in: Circle())
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.35), radius: 10, x: 0, y: 6)
                    .accessibilityLabel("Close")
            }
            .offset(y: 32)
        }
        .padding(.bottom, 32) // make space for the overhanging X
        .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout summary, total \(summary.totalXP) XP")
    }
}
