//
//  RealmPokeonCard.swift
//  Pokemon
//
//  Created by 김기현 on 3/16/24.
//

import Foundation
import RealmSwift

class RealmPokemonCard: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String
    @Persisted var hp: String?
    @Persisted var smallImageURL: String
    @Persisted var largeImageURL: String
    @Persisted var isFavorite: Bool = false

    convenience init(pokemonCard: PokemonCard) {
        self.init()
        self.id = pokemonCard.id
        self.name = pokemonCard.name
        self.hp = pokemonCard.hp
        self.smallImageURL = pokemonCard.images.small.absoluteString
        self.largeImageURL = pokemonCard.images.large.absoluteString
    }

    var images: PokemonCardImage {
        return PokemonCardImage(small: URL(string: smallImageURL)!, large: URL(string: largeImageURL)!)
    }
}
