import SwiftUI
struct MainContainerView: View {
    @State private var isSidebarVisible = false

    var body: some View {
        ZStack(alignment: .leading) {
            MainTabView {
                withAnimation {
                    isSidebarVisible.toggle()
                }
            }
            .disabled(isSidebarVisible)

            if isSidebarVisible {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .onTapGesture {
                        withAnimation {
                            isSidebarVisible = false
                        }
                    }

                SidebarView(isShowing: $isSidebarVisible)
                    .frame(width: 250)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}
