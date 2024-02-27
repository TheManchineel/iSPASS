//
//  iSPASSApp.swift
//  iSPASS
//

import SwiftUI
import UniformTypeIdentifiers

let spassFileType = UTType(exportedAs: "de.mpg.mpi-inf.spass")

struct TheoremProverView: View {
    @Environment(SpassNativeSync.self) var spassNative
    @Environment(SpassWasm.self) var spassWasm
    @State private var isImporting = false
    @AppStorage("nativeMode") private var isNative: Bool = false
    
    private func getRealSpass() -> SpassImplementation {
        return isNative ? spassNative : spassWasm
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Spass output:\n \(getRealSpass().outputText)").font(.system(.footnote).monospaced())
            }
            .padding()
            .navigationTitle("iSPASS Theorem Prover")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: { isImporting = true },
                        label: { Label("Open .SPASS", systemImage: "folder") }
                    )
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [spassFileType]
            ) { results in
                switch results {
                case .success(let fileurl):
                    if (fileurl.startAccessingSecurityScopedResource()) {
                        // TODO: (IMPORTANT!!! Find a proper way to handle file access, this is an obvious race condition)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            print("Relinquishing access to \(fileurl)")
                            fileurl.stopAccessingSecurityScopedResource()
                        }
                        let path = fileurl.path()
                        getRealSpass().run(args: ["-DocProof", path], url: fileurl)
                    } else {
                        NSLog("ERROR OPENING FILE!!!")
                    }
                case .failure(let error):
                    NSLog(error.localizedDescription)
                }
            }
        }
    }
}


struct SettingsView: View {
        @Environment(SpassWasm.self) var spassWasm
        @AppStorage("nativeMode") var isNative = false
        var body: some View {
            NavigationStack {
                VStack {
                    Form {
                        Section (header: Text("Debugging")) {
                            Toggle(isOn: $isNative) {
                                Text("Native mode ( broken :/ )")
                            }
                            Button("Test JS") {
                                spassWasm.webView?.evaluateJavaScript("console.log('Hello, world!')")
                            }
                            Button("Print SPwasSm output") {
                                print("Output: \(spassWasm.outputText)")
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal, content: {
                        Text("Settings").font(.headline)
                    })
                }
        }
    }
}

struct MainView: View {
    @Environment(SpassNativeSync.self) var spassNative
    @Environment(SpassWasm.self) var spassWasm
    var body: some View {
        TabView {
            TheoremProverView()
                .tabItem {
                    Label("Prover", systemImage: "square")
                }
                .environment(spassNative)
                .environment(spassWasm)
                .badge(10)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }.tint(.accent)
    }
}

@main
struct iSPASSApp: App {
    @State var spassNative = SpassNativeSync()
    @State var spassWasm = SpassWasm()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(spassNative)
                .environment(spassWasm)
        }
    }
}
