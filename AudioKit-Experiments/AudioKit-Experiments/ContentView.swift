import SwiftUI
struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
struct MasterView: View {
    var body: some View {
        Form {
            Section(header: Text("Demos")) {
                Group {
                    Text("Coming Soon...")
//                    NavigationLink("1. Drum Pads", destination: DrumPads())
                }
            }
        }.navigationBarTitle("AudioKit Experiments")
    }
}

#Preview {
    ContentView()
}
