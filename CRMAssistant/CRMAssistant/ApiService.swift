// ApiService.swift
import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int)
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .noData:
            return "No data received"
        }
    }
}

class ApiService {
    static let shared = ApiService()
    
    private let session = URLSession.shared
    
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers if provided
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check status code
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Decode response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    func requestString(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> String {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers if provided
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check status code
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Convert data to string
        guard let string = String(data: data, encoding: .utf8) else {
            throw APIError.noData
        }
        
        return string
    }
}
