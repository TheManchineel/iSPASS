//
//  WKUserContentController+JSLoggingBridge.swift
//  iSPASS
//

import Foundation
import WebKit

private let LOGGING_HANDLER_NAME = "loggingHandler"

// TODO: rewrite userscript to use stringified objects and render colored errors in Swift
private let overrideConsoleUserScript = """
    function log(emoji, type, args) {
      window.webkit.messageHandlers.\(LOGGING_HANDLER_NAME).postMessage(
        `${emoji} ${type}: ${Object.values(args)
          .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
          .map(v => v.substring(0, 3000)) // Limit msg to 3000 chars
          .join(", ")}`
      );
    }

    let originalLog = console.log;
    let originalWarn = console.warn;
    let originalError = console.error;
    let originalDebug = console.debug;

    console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) };
    console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) };
    console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) };
    console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) };

    window.addEventListener("error", function(e) {
       log("💥", "Exception: ", [`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`]);
    });
"""

private class LoggingMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("JS - \(message.body)")
    }
}

extension WKUserContentController {
    /// Redirects console output from a WKWebView to the stdout of the app.
    func enableJsLoggingBridge() {
        self.add(LoggingMessageHandler(), name: LOGGING_HANDLER_NAME)
        self.addUserScript(WKUserScript(source: overrideConsoleUserScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    }
}

