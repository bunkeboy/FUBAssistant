//
//  LeadResponse.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/10/25.
//


import Foundation

struct LeadResponse: Decodable {
    let people: [Lead]
}

struct Lead: Identifiable, Decodable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "firstName"
        case lastName = "lastName"
        case email
        case phone
    }
}
