
//
//  PokemonCardService.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya


private extension String {
    static let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
}

enum PokemonAPI {
    case fetchCards(query: String)
}

extension PokemonAPI: TargetType {
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
            return .requestParameters(parameters: ["apiKey": String.apiKey], encoding: URLEncoding.queryString)
        }
    }

    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}
