//
//  CallApi.swift
//  Project
//
//  Created by Tanishk Deo on 6/6/21.
//

import Foundation
import RxSwift

struct APIService {
    
    
    // Returns Observable of Google Speech API Result (Transcription)

    func transcribe(url: URL) -> Observable<Model.Transcription> {
        var task: URLSessionDataTask?
        return Observable.create { observer -> Disposable in
            if let request = generateRequestData(url: url) {
                task = URLSession.shared.dataTask(with: request) {
                    data, response, error in
                    if let data = data, let result = try? JSONDecoder().decode(Model.Transcription.self, from: data) {
                        observer.onNext(result)
                    } else if error != nil {
                        observer.onError(CallError.connection(description: "Could not connect to internet. Please check your connection and try again"))
                        return
                    } else {
                        observer.onError(CallError.transcription(description: "Could not transcribe data. Please try again."))
                    }
                }
                task?.resume()
            }
            return Disposables.create {
                task?.cancel()
            }
        }
        
    }
    
    
    
    // Basic Request Configuration
    
    enum APIConfig {
        static let scheme = "https"
        static let host = "speech.googleapis.com"
        static let path = "/v1/speech:recognize"
        static let key = "XXXX"
        
        
        static let config: [String: Any] =  [
            "encoding": "LINEAR16",
            "sampleRateHertz": 16000,
            "languageCode": "en-US",
            "enableWordTimeOffsets": true
        ]
    }
    
    
    private func createURLComponents() -> URLComponents {
        var components = URLComponents()
        components.host = APIConfig.host
        components.path = APIConfig.path
        components.scheme = APIConfig.scheme

        components.queryItems = [
            URLQueryItem(name: "key", value: APIConfig.key)
        ]
        return components
    }
    
    
    // Transforms CAF file to Base64 for Google Speech to Text API Request
    
    private func encodeInBase64(url: URL) -> String? {
        if let data = try? Data(contentsOf: url) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    
    
    // Returns the URL Request from URL
    
    private func generateRequestData(url: URL) -> URLRequest? {
        let dict: [String: Any] = [
            "config": APIConfig.config,
            "audio": ["content":encodeInBase64(url: url) ?? ""]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .sortedKeys), let url = createURLComponents().url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            return request
        }
        
        
        return nil
        
       

    }
}


