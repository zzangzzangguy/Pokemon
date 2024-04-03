
//
//  PokemonTarget.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya

typealias DictionaryType = [String: Any]

enum PokemonTarget {
    case fetchCards(parameters: DictionaryType)
}

extension PokemonTarget: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.pokemontcg.io/v2")!
    }

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
        case .fetchCards(let parameters):
            var params = parameters

            params["pageSize"] = params["pageSize"] ?? 20

            params["page"] = params["page"] ?? 1

            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "X-Api-Key": APIKeyManager.shared.apiKey
        ]
    }

}
