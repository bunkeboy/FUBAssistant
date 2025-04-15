//
//  IntentAnalysis.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/13/25.
//


// IntentAnalyzer.swift
import Foundation

// Define our response structure for API call intents
struct IntentAnalysis {
    enum CRMAction {
        case getPeople(query: String?)
        case getTasks(query: String?)
        case getAppointments(query: String?)
        case getLeads(query: String?)
        case unknown
    }
    
    let action: CRMAction
    let confidence: Double
    let originalQuery: String
}

class IntentAnalyzer {
    private let openAIAPIKey: String
    
    init(openAIAPIKey: String) {
        self.openAIAPIKey = openAIAPIKey
    }
    
    func analyzeIntent(userMessage: String) async throws -> IntentAnalysis {
        // Create URL
        Debug.log("Analyzing intent for message: \(userMessage)")
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }
        
        // Create prompt
        let systemPrompt = """
        You are a helpful assistant that analyzes user questions about a CRM system.
        Your task is to determine what Follow Up Boss API endpoint should be called.
        Respond with a JSON object that includes:
        1. action: The API action to take (getPeople, getTasks, getAppointments, getLeads, or unknown)
        2. query: Any search parameters to include (or null)
        3. confidence: Your confidence score from 0-1
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessage]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.2
        ]
        
        // Convert body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidResponse
        }
        
        // Create headers
        let headers = [
            "Authorization": "Bearer \(openAIAPIKey)",
            "Content-Type": "application/json"
        ]
        
        // Make request
        guard let responseString = try? await ApiService.shared.requestString(
            url: url,
            method: .post,
            headers: headers,
            body: jsonData
        ) else {
            throw APIError.invalidResponse
        }
        
        // Parse response
        guard let responseData = responseString.data(using: .utf8),
              let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.invalidResponse
        }
        
        // Parse the JSON response from the AI
        guard let jsonData = content.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let action = result["action"] as? String,
              let confidence = result["confidence"] as? Double else {
            throw APIError.invalidResponse
        }
        
        // Map the string action to our CRMAction enum
        let query = result["query"] as? String
        let crmAction: IntentAnalysis.CRMAction
        
        switch action {
        case "getPeople":
            crmAction = .getPeople(query: query)
        case "getTasks":
            crmAction = .getTasks(query: query)
        case "getAppointments":
            crmAction = .getAppointments(query: query)
        case "getLeads":
            crmAction = .getLeads(query: query)
        default:
            crmAction = .unknown
        }
        
        return IntentAnalysis(
            action: crmAction,
            confidence: confidence,
            originalQuery: userMessage
        )
    }
}
