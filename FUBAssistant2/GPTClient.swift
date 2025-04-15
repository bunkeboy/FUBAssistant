import Foundation

class GPTClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String = APIKeys.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    func processQuery(_ query: String) async throws -> String {
        // Create request to OpenAI API
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the prompt
        let prompt = """
        You are an assistant for a real estate CRM called Follow Up Boss.
        
        Determine which function would best handle this user query: "\(query)"
        
        Choose from these functions:
        - getLeads(filters) - Get leads with optional filtering
        - getLeadDetails(leadId) - Get details about a specific lead
        - getTasks(filters) - Get tasks with optional filtering
        - getUpcomingTasks(timeframe) - Get upcoming tasks for a timeframe (today, this_week, this_month)
        - getAppointments(timeframe, filters) - Get appointments for a timeframe with optional filtering
        
        Return a JSON object with:
        1. "function": The name of the function to call
        2. "parameters": A dictionary of parameter values for the function
        3. "explanation": A brief explanation of why you chose this function
        
        Examples:
        {"function": "getLeads", "parameters": {"source": "Zillow"}, "explanation": "User is asking about Zillow leads"}
        {"function": "getUpcomingTasks", "parameters": {"timeframe": "today"}, "explanation": "User wants to know today's tasks"}
        {"function": "getAppointments", "parameters": {"timeframe": "this_week"}, "explanation": "User is asking about this week's appointments"}
        """
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": query]
            ],
            "temperature": 0.7
        ]
        
        // Convert request body to JSON data
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Handle error response
            if let httpResponse = response as? HTTPURLResponse {
                print("Error: HTTP \(httpResponse.statusCode)")
                
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = (errorData["error"] as? [String: Any])?["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
            throw URLError(.badServerResponse)
        }
        
        // Parse the response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw NSError(domain: "GPTClientError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
    }
    
    func generateResponse(functionName: String, data: [String: Any], userQuery: String) async throws -> String {
        // Create request to OpenAI API
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert data to JSON string
        let dataString = try String(data: JSONSerialization.data(withJSONObject: data), encoding: .utf8) ?? "{}"
        
        // Prepare the prompt
        let prompt = """
        You are an assistant for a real estate CRM called Follow Up Boss.
        
        The user asked: "\(userQuery)"
        
        I called the function "\(functionName)" and got this data:
        \(dataString)
        
        Format a helpful, conversational response for the user based on this data. Keep your response brief and focused.
        For lists of people or tasks, mention the total count and only include details for up to 5 items.
        """
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        // Convert request body to JSON data
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Handle error response
            if let httpResponse = response as? HTTPURLResponse {
                print("Error: HTTP \(httpResponse.statusCode)")
                
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = (errorData["error"] as? [String: Any])?["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
            throw URLError(.badServerResponse)
        }
        
        // Parse the response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw NSError(domain: "GPTClientError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
    }
}
