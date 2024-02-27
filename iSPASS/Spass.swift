import Foundation
import System

extension String {
    
    func toCString() -> UnsafePointer<Int8>? {
        let nsSelf: NSString = self as NSString
        return nsSelf.cString(using: String.Encoding.utf8.rawValue)
    }
    
    var utf8CString: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }
}

func output(str: String) {
    NSLog(str)
    // NSLog("This never gets called")
}

class Spass {
    var stdoutFile: UnsafeMutablePointer<FILE>? = nil
    private let execQueue = DispatchQueue(label: "executeCommand", qos: .utility)
    private var stdoutActive = false
    let endOfTransmission = "\u{0004}"  // control-D, used to signal end of transmission
    
    private func onStdout(_ stdout: FileHandle) {
        NSLog("doesn't seem like this is ever getting called")
        if (!stdoutActive) { return }
        let data = stdout.availableData
        guard (data.count > 0) else {
            return
        }
        if let string = String(data: data, encoding: String.Encoding.utf8) {
                    // NSLog("UTF8 string: \(string)")
            output(str: string)
                    if (string.contains(endOfTransmission)) {
                        stdoutActive = false
                    }
        } else if let string = String(data: data, encoding: String.Encoding.ascii) {
            NSLog("Couldn't convert data in stdout using UTF-8, resorting to ASCII: \(string)")
            output(str: string)
            if (string.contains(endOfTransmission)) {
                stdoutActive = false
            }
        } else {
            NSLog("Couldn't convert data in stdout: \(data)")
        }
    }
    
    
    func run() {
        execQueue.async {
            NSLog("RUNNING SPASS NOW!!!")
            var stdoutPipe = Pipe()
            self.stdoutFile = fdopen(stdoutPipe.fileHandleForWriting.fileDescriptor, "w")
            stdoutPipe.fileHandleForReading.readabilityHandler = self.onStdout
            self.stdoutActive = true
            
            
            var argv: [UnsafePointer<Int8>?] = ["SPASS".toCString()!]
            let p_argv = UnsafeMutablePointer(mutating: argv)
            
            setOutputStream(self.stdoutFile)
            SPASS(Int32(argv.count), p_argv)
            
            let writeOpen = fcntl(stdoutPipe.fileHandleForWriting.fileDescriptor, F_GETFD)
            
            if (writeOpen >= 0) {
                // Pipe is still open, send information to close it, once all output has been processed.
                stdoutPipe.fileHandleForWriting.write(self.endOfTransmission.data(using: .utf8)!)
            }
            
            do {
                try stdoutPipe.fileHandleForWriting.close()
                try stdoutPipe.fileHandleForReading.close()
            }
            catch {
                NSLog("Exception in closing stdout_pipe: \(error)")
            }
        }
    }
}
