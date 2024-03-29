//
//  RealmManager.swift
//  Pokemon
//
//  Created by 김기현 on 3/18/24.
//

import Foundation
import RealmSwift
import RxSwift

class RealmManager {
    static let shared = RealmManager()
    private let realm: Realm
    private let favoriteUpdateSubject = PublishSubject<Void>()
    var favoriteUpdates: Observable<Void> {
           return favoriteUpdateSubject.asObservable()
       }


    private init() {
        do {
            let config = Realm.Configuration(
                schemaVersion: 3, // 스키마 버전 설정
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 3 {
                        // 새로운 프로퍼티 추가 마이그레이션 코드
                        migration.enumerateObjects(ofType: RealmPokemonCard.className()) { _, newObject in
                            newObject?["types"] = List<String>()
                            newObject?["rarity"] = ""
                        }
                    }
                }
            )
            self.realm = try Realm(configuration: config)
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }

    func getCard(withId id: String) -> RealmPokemonCard? {
        return realm.object(ofType: RealmPokemonCard.self, forPrimaryKey: id)
    }

    func addCard(_ card: RealmPokemonCard) {
        try? realm.write {
            print("Adding card to Realm: \(card.toPokemonCard())")

            realm.add(card)
        }
    }

    func updateFavorite(for cardID: String, with cardInfo: PokemonCard? = nil, isFavorite: Bool) {
        if let card = getCard(withId: cardID) {
               try? realm.write {
                   card.isFavorite = isFavorite

                   if let cardInfo = cardInfo {
                       card.name = cardInfo.name
                       card.hp = cardInfo.hp
                       card.smallImageURL = cardInfo.images.small.absoluteString
                       card.largeImageURL = cardInfo.images.large.absoluteString
                       card.types.removeAll()
                       card.types.append(objectsIn: cardInfo.types ?? [])
                       card.rarity = cardInfo.rarity
                   }

                   print("Updating favorite status in Realm: \(card.toPokemonCard())")
               }
           } else if let cardInfo = cardInfo {
               let newCard = RealmPokemonCard(pokemonCard: cardInfo)
               newCard.isFavorite = isFavorite
               addCard(newCard)
           }

           favoriteUpdateSubject.onNext(())
       }

    func getFavoriteCards() -> Results<RealmPokemonCard> {
            return realm.objects(RealmPokemonCard.self).filter("isFavorite == true")
        }

        var favoritesUpdated: Observable<Void> {
            return favoriteUpdateSubject.asObservable()
        }

        deinit {
            realm.invalidate()
        }
    }
