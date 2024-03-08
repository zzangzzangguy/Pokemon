
//
//  SearchRepositoryExtension+.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya

final class PokemonRepository: PokemonRepositoryType {
    private let provider: MoyaProvider<PokemonTarget>
    init() { provider = MoyaProvider<PokemonTarget>() }
}

extension PokemonRepository {
    func fetchCards(
        request: CardsRequest,
        completion: @escaping (Result<PokemonCards, Error>) -> Void
    ) {
        provider.request(.fetchCards(parameters: request.toDictionary)) { result in
            switch result {
            case .success(let response):
                do {
                    let data = try response.map(PokemonCards.self)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                print("네트워크 에러: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
