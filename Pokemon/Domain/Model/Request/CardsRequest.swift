//
//  CardsRequest.swift
//  Pokemon
//
//  Created by 김기현 on 2/13/24.
//

import Foundation

struct CardsRequest {
    let query: String?
    let page: Int?
    let pageSize: Int?

    init(
        query: String?,
        page: Int? = 1,
        pageSize: Int? = 10
    ) {
        self.query = query
        self.page = page
        self.pageSize = pageSize
    }

    var toDictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        if let query = query {
            dictionary["query"] = query
        }
        if let page = page {
            dictionary["page"] = page
        }
        if let pageSize = pageSize {
            dictionary["page_size"] = pageSize
        }
        return dictionary
    }
}
