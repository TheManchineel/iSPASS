import Foundation
import System

let endOfTransmission = "\u{0004}"

extension String {
    
    func toCString() -> UnsafePointer<Int8>? {
        let nsSelf: NSString = self as NSString
        return nsSelf.cString(using: String.Encoding.utf8.rawValue)
    }
    
    var utf8CString: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }
}

@Observable
class SpassNativeSync: SpassImplementation {
    var outputText: String = ""
    var stdoutFile: UnsafeMutablePointer<FILE>? = nil
    var semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    var callCount: Int = 0
    
    private func output(str: String) {
        NSLog("\(NSDate()) - Output:\n\(str)")
        self.outputText += "\(self.callCount)\n\(str)"
    }
    
    private func onStdout(_ stdout: FileHandle) {
        NSLog("OUTPUT RECEIVED")
        let data = stdout.availableData
        if var string = String(data: data, encoding: String.Encoding.utf8) {
            if string.contains(endOfTransmission)
            {
                NSLog("Signaling end of transmission")
                self.semaphore.signal()
            }
            string.replace(endOfTransmission, with:"")
            self.output(str: string)
            
        } else {NSLog("Text parsing error")}
    }
    
    func run(args: [String], url: URL) {
        self.callCount += 1
        self.outputText = ""
        let stdoutPipe: Pipe? = Pipe()
        self.stdoutFile = fdopen(stdoutPipe!.fileHandleForWriting.fileDescriptor, "w")
                
        stdoutPipe!.fileHandleForReading.readabilityHandler = self.onStdout
         setOutputStream(self.stdoutFile)
        
        var argv: [UnsafePointer<Int8>?] = ["SPASS".toCString()!]
        for arg in args {
            argv += [arg.toCString()]
        }
        
        let p_argv = UnsafeMutablePointer(mutating: argv)
        NSLog("About to call SPASS")
        SPASS(Int32(argv.count), p_argv)
        NSLog("SPASS COMPLETE")
        puts(endOfTransmission)
        fflush(stdoutFile)
        fclose(stdoutFile)
//        self.semaphore.wait()
    }
}
