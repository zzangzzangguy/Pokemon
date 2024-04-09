//
//  PokemonRepositoryType.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation

protocol PokemonRepositoryType {
    func fetchCards(
        request: CardsRequest,
        completion: @escaping (Result<PokemonCards, Error>) -> Void
    )
    
}
