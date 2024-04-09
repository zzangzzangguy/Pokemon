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
    @Persisted var types: List<String>
    @Persisted var rarity: String? 

    convenience init(pokemonCard: PokemonCard) {
        self.init()
        self.id = pokemonCard.id
        self.name = pokemonCard.name
        self.hp = pokemonCard.hp
        self.smallImageURL = pokemonCard.images.small.absoluteString
        self.largeImageURL = pokemonCard.images.large.absoluteString

        if let types = pokemonCard.types {
            self.types.append(objectsIn: types)
        }
        self.rarity = pokemonCard.rarity
    }

    var images: PokemonCardImage {
        let smallURL = URL(string: smallImageURL) ?? URL(string: "https://example.com/placeholder.png")!
        let largeURL = URL(string: largeImageURL) ?? URL(string: "https://example.com/placeholder.png")!
        return PokemonCardImage(small: smallURL, large: largeURL)
    }

    func toPokemonCard() -> PokemonCard {
        let hp = self.hp
        let types = Array(self.types)
        let rarity = self.rarity

        return PokemonCard(id: id, name: name, hp: hp, images: images, types: types, rarity: rarity)
    }
}
