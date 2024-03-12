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

    init(
        query: String? = nil,
        page: Int? = 1,
        pageSize: Int? = 250
    ) {
        self.query = query
        self.page = page
        self.pageSize = pageSize
    }

    var toDictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        if let query = query {
            dictionary["q"] = "name:\(query)*"
        }
        if let page = page {
            dictionary["page"] = page
        }
        if let pageSize = pageSize {
            dictionary["page_size"] = pageSize
        }
        print("Request Parameters: \(dictionary)") // 로그 출력
        return dictionary
    }
}
