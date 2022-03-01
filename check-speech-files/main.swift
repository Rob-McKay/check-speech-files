// Copyright 2022 Rob McKay
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
//  main.swift
//  check-speech-files
//
//  Created by Rob McKay on 28/02/2022.

import Foundation
import Speech

/**
 Write an error message to the standard error stream and exit with a failure code.
 
 - Parameter error: The message to be output to stderr
 
 - Returns: Never
*/
func reportErrorAndExit(error:String) -> Never
{
    error.data(using: .utf8)
        .map(FileHandle.standardError.write)
    exit(2)
}

/**
    Convert an audio file to text which is output to stdout
 
    - Parameter url: The url of the audio file to convert to text
 */
func recognizeFile(url:NSURL) -> SFSpeechRecognitionTask
{
    guard let recognizer = SFSpeechRecognizer() else {
        // A recognizer is not supported for the current locale
        reportErrorAndExit(error: "Recognizer not available")
    }
    
    if !recognizer.isAvailable {
        // The recognizer is not available right now
        reportErrorAndExit(error: "Recognizer not available")
    }
    
    let request = SFSpeechURLRecognitionRequest(url: url as URL)
    
    return recognizer.recognitionTask(with: request) { (result, error) in
        guard let result = result else {
            // Recognition failed, so check error for details and handle it
            reportErrorAndExit(error: "Failed to convert speech in file \(error.debugDescription)")
        }
        
        if result.isFinal {
            print(result.bestTranscription.formattedString)
        }
    }
}

// Check we have been invoked with a file parameter

if CommandLine.argc < 2 {
    "Usage: \(CommandLine.arguments[0]) <filename>".data(using: .utf8)
        .map(FileHandle.standardError.write)
    exit(1)
}

// Process the file
let task = recognizeFile(url: NSURL(fileURLWithPath: CommandLine.arguments[1]))

// Wait for the result
let runLoop = RunLoop.current
let distantFuture = NSDate.distantFuture as NSDate
while (task.state != SFSpeechRecognitionTaskState.completed) && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture as Date)
{}
