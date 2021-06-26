//
//  Model.swift
//  Test
//
//  Created by Tanishk Deo on 6/4/21.
//

import Foundation

enum Model {
    struct Transcription: Codable {
        let results: [Result]
    }
    
    struct Result: Codable {
        let alternatives: [Alternative]
    }
    
    struct Alternative: Codable {
        let transcript: String
        let confidence: Double
        let words: [Word]?
    }
    
    struct Word: Codable {
        let startTime: String
        let endTime: String
        let word: String
    }
}


enum CallError: Error, LocalizedError {
    case transcription(description: String)
    case connection(description: String)
    
    public var description: String? {
        switch self {
        case .transcription(let description),
             .connection(let description):
            return description
        }
    }
}

