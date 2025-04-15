//
//  Message.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/9/25.
//


import Foundation

struct Message: Identifiable {
    var id = UUID()
    var content: String
    var isUser: Bool
    var date: Date = Date()
}
