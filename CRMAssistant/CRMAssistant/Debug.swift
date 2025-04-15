//
//  LogLevel.swift
//  CRMAssistant
//
//  Created by Ryan Bunke on 4/13/25.
//


// Debug.swift
import Foundation

enum LogLevel {
    case info
    case warning
    case error
    
    var prefix: String {
        switch self {
        case .info: return "ℹ️ INFO"
        case .warning: return "⚠️ WARNING"
        case .error: return "🛑 ERROR"
        }
    }
}

class Debug {
    static var isEnabled = true
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        if isEnabled {
            let filename = URL(fileURLWithPath: file).lastPathComponent
            print("\(level.prefix) [\(filename):\(line) \(function)] \(message)")
        }
    }
    
    static func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log("\(error.localizedDescription)", level: .error, file: file, function: function, line: line)
        
        if let apiError = error as? APIError {
            log("API Error details: \(apiError)", level: .error, file: file, function: function, line: line)
        }
    }
}
