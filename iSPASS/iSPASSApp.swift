//
//  iSPASSApp.swift
//  iSPASS
//

import SwiftUI

let spass = Spass()

struct ContentView: View {
    var body: some View {
        Button(action: {
            spass.run()
        }) {
            Text("Run SPASS")
        }
    }
}

@main
struct iSPASSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
