//
//  Person.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/13/25.
//


// CRMService.swift
import Foundation

struct Person: Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let emails: [Email]?
    let phones: [Phone]?
    let stage: Stage?
    
    struct Email: Decodable {
        let value: String
        let type: String?
    }
    
    struct Phone: Decodable {
        let value: String
        let type: String?
    }
    
    struct Stage: Decodable {
        let id: Int
        let name: String
    }
}

struct Task: Decodable {
    let id: Int
    let title: String
    let dueDate: String?
    let completed: Bool
    let assignedTo: [User]?
    
    struct User: Decodable {
        let id: Int
        let name: String
    }
}

struct Appointment: Decodable {
    let id: Int
    let title: String
    let startDate: String
    let endDate: String
    let note: String?
}

class CRMService {
    private let apiKey: String
    private let baseURL = "https://api.followupboss.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func createBasicAuthHeader() -> String {
        let authString = "\(apiKey):"
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        return "Basic \(base64Auth)"
    }
    
    func getPeople(query: String? = nil) async throws -> [Person] {
        var urlComponents = URLComponents(string: "\(baseURL)/people")!
        
        if let query = query {
            urlComponents.queryItems = [URLQueryItem(name: "search", value: query)]
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let headers = [
            "Authorization": createBasicAuthHeader(),
            "Content-Type": "application/json"
        ]
        
        struct PeopleResponse: Decodable {
            let people: [Person]
        }
        
        let response = try await ApiService.shared.request(
            url: url,
            headers: headers,
            responseType: PeopleResponse.self
        )
        
        return response.people
    }
    
    func getTasks(query: String? = nil) async throws -> [Task] {
        var urlComponents = URLComponents(string: "\(baseURL)/tasks")!
        
        if let query = query {
            urlComponents.queryItems = [URLQueryItem(name: "search", value: query)]
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let headers = [
            "Authorization": createBasicAuthHeader(),
            "Content-Type": "application/json"
        ]
        
        struct TasksResponse: Decodable {
            let tasks: [Task]
        }
        
        let response = try await ApiService.shared.request(
            url: url,
            headers: headers,
            responseType: TasksResponse.self
        )
        
        return response.tasks
    }
    
    func getAppointments(query: String? = nil) async throws -> [Appointment] {
        var urlComponents = URLComponents(string: "\(baseURL)/appointments")!
        
        if let query = query {
            urlComponents.queryItems = [URLQueryItem(name: "search", value: query)]
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let headers = [
            "Authorization": createBasicAuthHeader(),
            "Content-Type": "application/json"
        ]
        
        struct AppointmentsResponse: Decodable {
            let appointments: [Appointment]
        }
        
        let response = try await ApiService.shared.request(
            url: url,
            headers: headers,
            responseType: AppointmentsResponse.self
        )
        
        return response.appointments
    }
}