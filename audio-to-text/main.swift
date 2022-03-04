//  main.swift
//
//  Convert an audio file to text
//
//  Created by Rob McKay on 28/02/2022.
//
//  Copyright 2022 Rob McKay
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Speech
import ArgumentParser

/**
 Write an error message to the standard error stream and exit with a failure code.
 
 - Parameter error: The message to be output to stderr
 
 - Returns: Never
*/
func reportErrorAndExit(error:String) -> Never
{
    error.data(using: .utf8)
        .map(FileHandle.standardError.write)
    "\n".data(using: .utf8)
        .map(FileHandle.standardError.write)
    exit(2)
}

/**
    Convert an audio file to text which is output to stdout
 
    - Parameter url: The url of the audio file to convert to text
 */
func recognizeFile(url:NSURL, locale:String) -> SFSpeechRecognitionTask
{
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) else {
        // A recognizer is not supported for the current locale
        reportErrorAndExit(error: "Recognizer not available")
    }
    
    if !recognizer.isAvailable {
        // The recognizer is not available right now
        reportErrorAndExit(error: "Recognizer is unavailable")
    }
    
    recognizer.defaultTaskHint = SFSpeechRecognitionTaskHint.dictation
    
    let request = SFSpeechURLRecognitionRequest(url: url as URL)
    
    request.taskHint = SFSpeechRecognitionTaskHint.dictation
    
    return recognizer.recognitionTask(with: request) { (result, error) in
        guard let result = result else {
            // Recognition failed, so check error for details and handle it
            reportErrorAndExit(error: "Failed to convert speech in file \(error.debugDescription.description)")
        }
        
        if result.isFinal {
            print(result.bestTranscription.formattedString)
        }
    }
}

struct Dictation: ParsableCommand
{
    static let configuration = CommandConfiguration(commandName: CommandLine.arguments[0], abstract: "Convert speech file to text.")
    
    @Argument
    var inputFile: String

    @Option(name: [.short, .customLong("locale")], help: "The speech locale to use.")
    var locale: String = "en-GB"

    mutating func run() throws {
        // Process the file
        let task = recognizeFile(url: NSURL(fileURLWithPath: inputFile), locale: locale)

        // Wait for the result
        let runLoop = RunLoop.current
        let distantFuture = NSDate.distantFuture as NSDate

        while (task.state != SFSpeechRecognitionTaskState.completed) && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture as Date)
        {}
    }
}

Dictation.main()
    
