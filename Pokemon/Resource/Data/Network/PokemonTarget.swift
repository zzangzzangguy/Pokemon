
//
//  PokemonTarget.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya

enum PokemonTarget {
    case fetchCards(query: String, page: Int)
}

extension PokemonTarget: TargetType {
    var baseURL: URL { return URL(string: "https://api.pokemontcg.io/v2")! }

    var path: String {
        switch self {
        case .fetchCards:
            return "/cards"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchCards:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .fetchCards(let query):
            return .requestParameters(parameters: ["q": query, "page": 1, "pageSize": 250], encoding: URLEncoding.queryString)

        }
    }

    var headers: [String : String]? {
        return ["Content-Type": "application/json", "X-Api-Key": APIKeyManager.shared.apiKey]
    }
}
