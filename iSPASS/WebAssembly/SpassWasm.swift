//
//  SpassWasm.swift
//  iSPASS
//

import Foundation
import WebKit

@Observable
class SpassWasm: SpassImplementation /*, OutputTextable */ {
    public var webView: WKWebView?
    public var outputText: String = ""
    
    public func run(args: [String], url: URL) {
        print("RUNNING SPASS...")
        self.outputText = ""
        do {
            let theoremFileData = try Data(contentsOf: url)
            self.webView!.evaluateJavaScript("runSpass('\(theoremFileData.base64EncodedString())', ['-DocProof']);") /// We cannot get output from SPASS to a callback, since runSpass is async
        }
        catch {
            outputText = "ERROR: \(error)"
        }
    }
    
    private class SpassStdoutHandler: NSObject, WKScriptMessageHandler {
        var spassWasmInstance: SpassWasm
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            spassWasmInstance.outputText += message.body as! String
            print(message.body as! String)
        }
        init(spassWasmInstance: SpassWasm) {
            self.spassWasmInstance = spassWasmInstance
        }
    }
    
    init() {
        let userContentController = WKUserContentController()
        let webViewConfig = WKWebViewConfiguration()
        userContentController.enableJsLoggingBridge()
        userContentController.add(SpassStdoutHandler(spassWasmInstance: self), name: "wasiStdoutHandler")
        webViewConfig.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: webViewConfig)
        
        let spassUrl = Bundle.main.url(forResource: "spassWasm", withExtension: "html")!
        print(spassUrl)
        webView!.loadFileURL(spassUrl, allowingReadAccessTo: spassUrl.deletingLastPathComponent())
        
///       Should not be needed (unless JS doesn't run automatically on app start without the app in view, which doesn't seem to be happening anymore):
//
//        var viewToAttachSpassTo = UIApplication.shared.windows.first!
//        viewToAttachSpassTo.addSubview(webView)
//
///       on destroy, you then should call .removeFromSuperview()
    }
}
