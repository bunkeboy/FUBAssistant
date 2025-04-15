//
//  MessageBubble.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/9/25.
//


import SwiftUI

struct MessageBubble: View {
    var message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}
