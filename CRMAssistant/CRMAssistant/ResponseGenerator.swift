//
//  ResponseGenerator.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/13/25.
//


// ResponseGenerator.swift
import Foundation

class ResponseGenerator {
    private let openAIAPIKey: String
    
    init(openAIAPIKey: String) {
        self.openAIAPIKey = openAIAPIKey
    }
    
    func generateResponse(userMessage: String, crmData: Any) async throws -> String {
        // Create URL
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }
        
        // Create prompt
        let systemPrompt = """
        You are a helpful CRM assistant for real estate agents. Your job is to provide clear, concise responses about CRM data.
        When providing responses:
        1. Be brief and to the point
        2. Only include relevant information
        3. Format lists and dates in a readable way
        4. Use a friendly, professional tone
        """
        
        // Convert CRM data to a string
        let crmDataString: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: crmData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            crmDataString = jsonString
        } else if let crmDataArray = crmData as? [Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: crmDataArray, options: .prettyPrinted),
                  let jsonString = String(data: jsonData, encoding: .utf8) {
            crmDataString = jsonString
        } else {
            crmDataString = String(describing: crmData)
        }
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessage],
            ["role": "system", "content": "Here is the data from the CRM system: \(crmDataString)"]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.7
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
        
        return content
    }
}