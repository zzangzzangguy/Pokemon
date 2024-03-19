//
//  RealmManager.swift
//  Pokemon
//
//  Created by 김기현 on 3/18/24.
//

import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()

    private let realm: Realm

    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("초기화 실패: \(error)")
        }
    }

    func getCard(withId id: String) -> RealmPokemonCard? {
        return realm.object(ofType: RealmPokemonCard.self, forPrimaryKey: id)
    }

    func addCard(_ card: RealmPokemonCard) {
        do {
            try realm.write {
                realm.add(card)
            }
        } catch {
            print("카드 추가 실패: \(error)")
        }
    }

    func updateFavorite(for cardID: String, isFavorite: Bool) {
        do {
            let realm = try Realm()
            if let card = realm.object(ofType: RealmPokemonCard.self, forPrimaryKey: cardID) {
                try realm.write {
                    card.isFavorite = isFavorite
                }
            } else {
                let newCard = RealmPokemonCard()
                newCard.id = cardID
                newCard.isFavorite = isFavorite
                try realm.write {
                    realm.add(newCard)
                }
            }
        } catch {
            print("업데이트 실패: \(error)")
        }
    }

    func getFavoriteCardIDs() -> [String] {
        let favoriteCards = realm.objects(RealmPokemonCard.self)
            .filter("isFavorite == true")
        return favoriteCards.map { $0.id }
    }
}
