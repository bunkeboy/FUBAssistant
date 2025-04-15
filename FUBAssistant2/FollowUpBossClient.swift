import Foundation

class FollowUpBossClient {
    private let apiKey: String
    private let baseURL = "https://api.followupboss.com/v1/"
    
    init(apiKey: String = APIKeys.followUpBossAPIKey) {
        self.apiKey = apiKey
    }
    
    // Get leads with filtering options
    func getLeads(filters: [String: Any] = [:]) async throws -> [String: Any] {
        return try await makeRequest(endpoint: "people", method: "GET", queryParams: filters)
    }
    
    // Get details for a specific lead
    func getLeadDetails(leadId: Int) async throws -> [String: Any] {
        return try await makeRequest(endpoint: "people/\(leadId)", method: "GET")
    }
    
    // Get tasks with filtering options
    func getTasks(filters: [String: Any] = [:]) async throws -> [String: Any] {
        return try await makeRequest(endpoint: "tasks", method: "GET", queryParams: filters)
    }
    
    // Get upcoming tasks for a timeframe
    func getUpcomingTasks(timeframe: String) async throws -> [String: Any] {
        let today = ISO8601DateFormatter().string(from: Date())
        
        var endDate = Date()
        switch timeframe {
        case "today":
            // End date stays as today
            break
        case "this_week":
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case "this_month":
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        default:
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        let endDateStr = ISO8601DateFormatter().string(from: endDate)
        
        let filters: [String: Any] = [
            "dueDate": today,
            "dueDateEnd": endDateStr,
            "status": "active"
        ]
        
        return try await makeRequest(endpoint: "tasks", method: "GET", queryParams: filters)
    }
    
    // Get appointments with filtering
    func getAppointments(timeframe: String, filters: [String: Any] = [:]) async throws -> [String: Any] {
        var queryParams = filters
        
        // Add date ranges based on timeframe
        let today = ISO8601DateFormatter().string(from: Date())
        queryParams["fromDate"] = today
        
        var endDate = Date()
        switch timeframe {
        case "today":
            // End date stays as today
            break
        case "tomorrow":
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case "this_week":
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case "this_month":
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        default:
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        let endDateStr = ISO8601DateFormatter().string(from: endDate)
        queryParams["toDate"] = endDateStr
        
        return try await makeRequest(endpoint: "events", method: "GET", queryParams: queryParams)
    }
    
    // Generic request method to avoid code duplication
    private func makeRequest(endpoint: String, method: String, queryParams: [String: Any] = [:], body: [String: Any]? = nil) async throws -> [String: Any] {
        var urlComponents = URLComponents(string: baseURL + endpoint)!
        
        // Add query parameters if provided
        if !queryParams.isEmpty {
            var queryItems: [URLQueryItem] = []
            
            for (key, value) in queryParams {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
            
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication header
        let loginString = apiKey + ":"
        let loginData = loginString.data(using: .utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Add request body if provided
        if let body = body, method != "GET" {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Handle error response
            if let httpResponse = response as? HTTPURLResponse {
                print("Error: HTTP \(httpResponse.statusCode)")
                
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
            throw URLError(.badServerResponse)
        }
        
        // Parse the JSON response
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        return jsonResponse
    }
}
