struct WorkoutSummaryCard: View {
    let summary: WorkoutSummary
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout Summary").font(.headline)
                    Text(summary.templateName)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                    Text("\(summary.totalXP)")
                        .font(.headline)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark").padding(8)
                }
            }

            // List of exercises (limited height)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(summary.exercises) { ex in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(ex.name).bold()
                                Spacer()
                                Text("+\(ex.totalXP) XP")
                                    .font(.subheadline).bold()
                            }
                            if ex.weight > 0 {
                                Text("Weight: \(ex.weight, specifier: "%.1f")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            ForEach(ex.sets) { s in
                                HStack {
                                    Text("Set \(s.index)")
                                    Spacer()
                                    Text("\(s.completed)/\(s.target) reps")
                                        .foregroundStyle(.secondary)
                                    Text("+\(s.xp) XP")
                                        .font(.caption).bold().padding(.leading, 8)
                                }
                                .font(.caption)
                            }
                            Divider().opacity(0.15)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 280)

            // Footer total
            HStack {
                Text("Total XP Earned").font(.subheadline).bold()
                Spacer()
                Text("\(summary.totalXP)").font(.subheadline).bold()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout summary, total \(summary.totalXP) XP")
    }
}
