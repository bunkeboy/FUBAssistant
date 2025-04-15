import Foundation

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let followUpBossClient = FollowUpBossClient()
    private let gptClient = GPTClient()
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // Add user message to chat
        let userMessage = Message(content: inputText, isFromUser: true)
        messages.append(userMessage)
        
        // Clear input field
        let userQuery = inputText
        inputText = ""
        
        // Process the message
        Task {
            await processUserQuery(userQuery)
        }
    }
    
    @MainActor
    private func processUserQuery(_ query: String) async {
        isLoading = true
        
        // Add a loading message
        let processingMessage = Message(content: "Processing your request...", isFromUser: false)
        messages.append(processingMessage)
        
        do {
            // First, use GPT to determine which function to call
            let gptResponse = try await gptClient.processQuery(query)
            
            // Parse the JSON response from GPT
            guard let jsonData = gptResponse.data(using: .utf8),
                  let responseDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let functionName = responseDict["function"] as? String,
                  let parameters = responseDict["parameters"] as? [String: Any] else {
                
                throw NSError(domain: "ProcessError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't parse GPT response"])
            }
            
            // Call the appropriate function based on GPT's analysis
            var responseData: [String: Any] = [:]
            
            switch functionName {
            case "getLeads":
                responseData = try await followUpBossClient.getLeads(filters: parameters)
            case "getLeadDetails":
                if let leadId = parameters["leadId"] as? Int {
                    responseData = try await followUpBossClient.getLeadDetails(leadId: leadId)
                } else {
                    throw NSError(domain: "ParameterError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing leadId parameter"])
                }
            case "getTasks":
                responseData = try await followUpBossClient.getTasks(filters: parameters)
            case "getUpcomingTasks":
                if let timeframe = parameters["timeframe"] as? String {
                    responseData = try await followUpBossClient.getUpcomingTasks(timeframe: timeframe)
                } else {
                    throw NSError(domain: "ParameterError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing timeframe parameter"])
                }
            case "getAppointments":
                if let timeframe = parameters["timeframe"] as? String {
                    // Extract any other filters if present
                    var filters: [String: Any] = [:]
                    for (key, value) in parameters {
                        if key != "timeframe" {
                            filters[key] = value
                        }
                    }
                    responseData = try await followUpBossClient.getAppointments(timeframe: timeframe, filters: filters)
                } else {
                    throw NSError(domain: "ParameterError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing timeframe parameter"])
                }
            default:
                throw NSError(domain: "FunctionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown function: \(functionName)"])
            }
            
            // Remove the loading message
            self.messages.removeLast()
            
            // Use GPT to generate a natural language response
            let formattedResponse = try await gptClient.generateResponse(
                functionName: functionName,
                data: responseData,
                userQuery: query
            )
            
            // Add the response to the chat
            let assistantMessage = Message(content: formattedResponse, isFromUser: false)
            self.messages.append(assistantMessage)
            
        } catch {
            // Remove the loading message
            self.messages.removeLast()
            
            // Add an error message
            let errorMessage = Message(content: "Sorry, I encountered an error: \(error.localizedDescription)", isFromUser: false)
            self.messages.append(errorMessage)
        }
        
        isLoading = false
    }
}
