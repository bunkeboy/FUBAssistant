//
//  FollowUpBossService.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/10/25.
//


import Foundation

class FollowUpBossService {
    // Your Follow Up Boss API key
    private let apiKey = "fka_0czGO2mOUsmr6GRe7qrZ3HjkuLyd3to08M"
    private let baseUrl = "https://api.followupboss.com/v1"
    
    // Get all leads (people)
    func getLeads(completion: @escaping ([Lead]?, Error?) -> Void) {
        let endpoint = "/people"
        makeRequest(endpoint: endpoint) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "FollowUpBossService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(LeadResponse.self, from: data)
                completion(response.people, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    // Create a basic API request
    private func makeRequest(endpoint: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: baseUrl + endpoint) else {
            completion(nil, NSError(domain: "FollowUpBossService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add Basic Auth header with API key
        let authString = "Basic " + Data("\(apiKey):".utf8).base64EncodedString()
        request.addValue(authString, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            completion(data, nil)
        }
        
        task.resume()
    }
}
