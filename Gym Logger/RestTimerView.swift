import SwiftUI
import UIKit

struct RestTimerView: View {
    @AppStorage("restTimerAutoStart") var autoStartTimer: Bool = true
    @Binding var isRunning: Bool
    @Binding var remainingTime: Int
    @Binding var showingTimePicker: Bool

    var restTime: Int
    var onStart: () -> Void
    var onStop: () -> Void

    var body: some View {
        Button(action: {
            isRunning ? onStop() : onStart()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text(timeString(from: remainingTime))
                    .font(.system(.body, design: .monospaced).bold())
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
        }
        .foregroundColor(.blue)
        .contextMenu {
            Button {
                showingTimePicker = true
            } label: {
                Label("Set Rest Time", systemImage: "clock.arrow.circlepath")
            }

            Toggle(isOn: $autoStartTimer) {
                Label("Auto-start on Done", systemImage: "bolt.fill")
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
