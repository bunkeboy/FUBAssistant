import Foundation
import SwiftUI

class MessageStore: ObservableObject {
    @Published var messages: [Message] = []
    private let intentAnalyzer: IntentAnalyzer
    private let crmService: CRMService
    private let responseGenerator: ResponseGenerator
    private var isProcessing = false
    
    init() {
        self.intentAnalyzer = IntentAnalyzer(openAIAPIKey: APIKeys.openAI)
        self.crmService = CRMService(apiKey: APIKeys.followUpBoss)
        self.responseGenerator = ResponseGenerator(openAIAPIKey: APIKeys.openAI)
        
        // Add welcome message
        let welcomeMessage = Message(content: "Hello! I'm your CRM Assistant. How can I help you today?", isUser: false)
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ text: String, isUser: Bool) {
        let newMessage = Message(content: text, isUser: isUser)
        messages.append(newMessage)
        
        // If this is a user message, process it
        if isUser && !isProcessing {
            processUserMessage(text)
        }
    }
    
    private func processUserMessage(_ message: String) {
        // Show typing indicator
        isProcessing = true
        let typingMessage = Message(content: "...", isUser: false)
        messages.append(typingMessage)
        
        // Simple approach - just return a fixed response for now
        // This will let us test the UI while we figure out the async code
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Remove typing indicator
            self.messages.removeAll(where: { $0.content == "..." })
            
            // Add a mock response for testing
            self.sendMessage("I'm a placeholder response. The AI and CRM integration will be implemented soon.", isUser: false)
            self.isProcessing = false
        }
    }
}
