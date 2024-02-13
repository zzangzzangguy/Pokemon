
//
//  SearchRepositoryExtension+.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya

class SearchRepositoryImpl: SearchRepository {
    private let provider: MoyaProvider<PokemonTarget>

    init(provider: MoyaProvider<PokemonTarget> = MoyaProvider<PokemonTarget>()) {
        self.provider = provider
    }

    func searchCards(with query: String, page: Int, completion: @escaping (Result<[PokemonCard], Error>) -> Void) {
        provider.request(.fetchCards(query: query, page: page)) { result in
            switch result {
            case .success(let response):
                do {
                    let cardsDataModels = try response.map(PokemonCardResponse.self).data
                    let cards = cardsDataModels.map { $0.toDomain() }
                    completion(.success(cards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
