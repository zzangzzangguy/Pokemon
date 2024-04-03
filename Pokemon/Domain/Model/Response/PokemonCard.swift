//
//  PokemonCard.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation

struct PokemonCards: Codable {
    let data: [PokemonCard]
    let totalCount: Int
    let pageSize: Int
    let count: Int
    let page: Int
    
}
struct PokemonCard: Codable {
    let id: String
    let name: String
    let hp: String?
    let images: PokemonCardImage
    let types: [String]?
    let rarity: String? 
}

struct PokemonCardImage: Codable {
    let small: URL
    let large: URL
}

extension PokemonCard: Equatable {
    static func == (lhs: PokemonCard, rhs: PokemonCard) -> Bool {
        return lhs.id == rhs.id
    }
}
