//
//  Message.swift
//  FUBAssistant2
//
//  Created by Ryan Bunke on 4/14/25.
// hi


import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let date: Date = Date()
}
