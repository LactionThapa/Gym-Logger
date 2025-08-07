import SwiftUI

struct RestTimerView: View {
    @Binding var isRunning: Bool
    @Binding var remainingTime: Int
    let restTime: Int

    var body: some View {
        Button(action: {
            isRunning ? stopTimer() : startTimer()
        }) {
            HStack(spacing: 8) {
                Text(timeString(from: remainingTime))
                    .font(.system(.body, design: .monospaced).bold())
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .overlay(
                Capsule()
                    .stroke(Color.blue, lineWidth: 2)
            )
            .foregroundColor(Color.blue)
        }
    }

    private func startTimer() {
        isRunning = true
        remainingTime = restTime
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                isRunning = false
                timer.invalidate()
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        remainingTime = restTime
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
