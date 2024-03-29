//
//  CardsRequest.swift
//  Pokemon
//
//  Created by 김기현 on 2/13/24.
//

import Foundation

struct CardsRequest {
    var query: String?
    var page: Int?
    var pageSize: Int?
    var rarity: String?
    var type: String?

    init(
        query: String? = nil,
        page: Int? = 1,
        pageSize: Int? = 250,
        rarity: String? = nil,
        type: String? = nil
    ) {
        self.query = query
        self.page = page
        self.pageSize = pageSize
        self.rarity = rarity
        self.type = type
    }

    var toDictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        var queryItems: [String] = []

        if let query = query {
            queryItems.append("name:\(query)*")
        }

        if let rarity = rarity {
            queryItems.append("rarity:\(rarity)")
        }
        if let type = type {
                    queryItems.append("type:\(type)")
                }


        if !queryItems.isEmpty {
            dictionary["q"] = queryItems.joined(separator: " ")
        }

        if let page = page {
            dictionary["page"] = page
        }

        if let pageSize = pageSize {
            dictionary["page_size"] = pageSize
        }

        print("Request Parameters: \(dictionary)")
        return dictionary
    }
}
