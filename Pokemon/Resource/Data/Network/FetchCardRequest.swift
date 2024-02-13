//
//  FetchCardRequest.swift
//  Pokemon
//
//  Created by 김기현 on 2/13/24.
//

import Foundation

struct FetchCardsRequest {
    let query: String
    let page: Int
    let pageSize: Int = 250
}
