//
//  APIKeyManager.swift
//  Pokemon
//
//  Created by 김기현 on 2/13/24.
//

import Foundation

final class APIKeyManager {

    static let shared = APIKeyManager()

    var apiKey: String {
        return ProcessInfo.processInfo.environment["API_KEY"] ?? ""
    }
}
