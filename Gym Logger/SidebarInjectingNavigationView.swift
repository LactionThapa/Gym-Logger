import SwiftUI

struct SidebarInjectingNavigationView<Content: View>: View {
    let toggleSidebar: () -> Void
    let content: Content

    init(toggleSidebar: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.toggleSidebar = toggleSidebar
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                        }
                    }
                }
        }
    }
}
