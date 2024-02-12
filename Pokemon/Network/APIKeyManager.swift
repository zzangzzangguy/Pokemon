//
//  APIKeyManager.swift
//  Pokemon
//
//  Created by 김기현 on 2/13/24.
//

import Foundation

class APIKeyManager {
    static let shared = APIKeyManager()
    private init() {}

    var apiKey: String {
        return ProcessInfo.processInfo.environment["API_KEY"] ?? ""
          }
      }
