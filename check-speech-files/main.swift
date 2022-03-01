//
//  main.swift
//  check-speech-files
//
//  Created by Rob McKay on 28/02/2022.
//

import Foundation
import Speech

var complete = false

func recognizeFile(url:NSURL) {
    guard let myRecognizer = SFSpeechRecognizer() else {
        // A recognizer is not supported for the current locale
        "Recognizer not available".data(using: .utf8)
            .map(FileHandle.standardError.write)
        exit(2)
    }
    
    if !myRecognizer.isAvailable {
        // The recognizer is not available right now
        "Recognizer not available".data(using: .utf8)
            .map(FileHandle.standardError.write)
        exit(2)
    }
    
    let request = SFSpeechURLRecognitionRequest(url: url as URL)
    
    
    myRecognizer.recognitionTask(with: request) { (result, error) in
        guard let result = result else {
            // Recognition failed, so check error for details and handle it
            "Failed to convert speech in file \(error.debugDescription)".data(using: .utf8)
                .map(FileHandle.standardError.write)
            exit(2)
        }
        
        // Print the speech that has been recognized so far
        if result.isFinal {
            print(result.bestTranscription.formattedString)
            complete = true
        }
    }
}

if CommandLine.argc < 2 {
    "Usage: \(CommandLine.arguments[0]) <filename>".data(using: .utf8)
        .map(FileHandle.standardError.write)
    exit(1)
}

let args = CommandLine.arguments


recognizeFile(url: NSURL(fileURLWithPath: CommandLine.arguments[1]))

let runLoop = RunLoop.current
let distantFuture = NSDate.distantFuture as NSDate
while !complete && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture as Date) {}
