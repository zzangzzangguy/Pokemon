
//
//  PokemonCardDataModel.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation

struct PokemonCardResponse: Decodable {
    let data: [PokemonCardDataModel]
}

struct PokemonCardDataModel: Decodable {
    let id: String
    let name: String
    let hp: String?
    let images: CardImages

    struct CardImages: Decodable {
        let small: String
        let large: String
    }
}

extension PokemonCardDataModel {
    func toDomain() -> PokemonCard {
        return PokemonCard(
            id: id,
            name: name,
            hp: hp,
            imageUrlSmall: URL(string: images.small)!,
            imageUrlLarge: URL(string: images.large)!
        )
    }
}
