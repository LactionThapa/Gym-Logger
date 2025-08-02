import SwiftUI

struct MainContainerView: View {
    @State private var isSidebarVisible = false

    var body: some View {
        ZStack {
            // Your main app tabs
            MainTabView()
                .disabled(isSidebarVisible) // Prevent interaction when sidebar open
                .overlay(
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    isSidebarVisible.toggle()
                                }
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .font(.title)
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                )

            // Sidebar
            if isSidebarVisible {
                SidebarView(isShowing: $isSidebarVisible)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}
