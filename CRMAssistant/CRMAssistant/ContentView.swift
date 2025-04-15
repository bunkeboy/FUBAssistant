import SwiftUI

struct ContentView: View {
    @StateObject var messageStore = MessageStore()
    @State private var messageText = ""
    @State private var scrollToBottom = false
    @State private var showDebug = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Debug panel (toggle with showDebug)
                if showDebug {
                    VStack {
                        Text("Debug Info")
                            .font(.headline)
                        Text(messageStore.debugInfo)
                            .font(.system(.footnote, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(messageStore.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.top, 10)
                        .onChange(of: messageStore.messages.count) { _ in
                            withAnimation {
                                if let lastId = messageStore.messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 5)
                
                // Input area
                HStack {
                    TextField("Type a message", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)
                    
                    Button(action: {
                        if !messageText.isEmpty {
                            messageStore.sendMessage(messageText, isUser: true)
                            messageText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("CRM Assistant")
            .navigationBarItems(trailing: Button(action: {
                showDebug.toggle()
            }) {
                Image(systemName: showDebug ? "info.circle.fill" : "info.circle")
            })
        }
    }
}
