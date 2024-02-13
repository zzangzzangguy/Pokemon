//
//  SearchRepositoryProtocol.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation

protocol SearchRepository {
    func searchCards(with query: String, page: Int, completion: @escaping (Result<[PokemonCard], Error>) -> Void)
}
