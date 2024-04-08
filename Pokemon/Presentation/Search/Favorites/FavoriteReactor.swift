//
//  FavoriteReactor.swift
//  Pokemon
//
//  Created by 김기현 on 3/21/24.
//
import ReactorKit
import RxSwift
import RealmSwift
import Toast
import UIKit

final class FavoriteReactor: Reactor {
    var initialState: State = State()
    let viewSubject = PublishSubject<Mutation>()
    var disposeBag = DisposeBag()

    enum Action {
        case loadFavorites
        case toggleFavorite(String, Bool)
        case filterFavorites(String)
        case setFavorites([RealmPokemonCard])
    }

    enum Mutation: Equatable {
        case setFavorites([RealmPokemonCard])
        case setSelectedRarity(String)
        case reloadTableView
        case setFilteredFavorites([RealmPokemonCard])
    }
    struct State {
        var favoriteCards: [RealmPokemonCard] = []
        var selectedRarity: String = "All"
        var filteredFavorites: [RealmPokemonCard] = []

    }
    init() {
        self.initialState = State()

        RealmManager.shared.favoritesUpdated
                .observe(on: MainScheduler.instance)
                .map { _ in Action.loadFavorites }
                .bind(to: self.action)
                .disposed(by: disposeBag)
        }



    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadFavorites:
            let favorites = Array(RealmManager.shared.getFavoriteCards())
            let filteredFavorites = filterFavorites(favorites, by: currentState.selectedRarity)
                   return .concat([
                       .just(.setFavorites(favorites)),
                       .just(.setFilteredFavorites(filteredFavorites)),
                       .just(.reloadTableView)

                   ])
                   .observe(on: MainScheduler.instance) 

        case .toggleFavorite(let cardID, let isFavorite):
            if let card = currentState.favoriteCards.first(where: { $0.id == cardID })?.toPokemonCard() {
                RealmManager.shared.updateFavorite(for: cardID, with: card, isFavorite: isFavorite)
                AppState.shared.favoriteStatusChanged.onNext(cardID)
                if let updatedCard = RealmManager.shared.getCard(withId: cardID)?.toPokemonCard() {
                    print("즐겨찾기 상태 변경됨 - 이름: \(updatedCard.name), 타입: \(updatedCard.types?.joined(separator: ", ") ?? "-"), 등급: \(updatedCard.rarity ?? "-"), HP: \(updatedCard.hp ?? "-")")
                    let toastMessage = isFavorite ? "\(updatedCard.name)이(가) 즐겨찾기에 추가되었습니다." : "\(updatedCard.name)이(가) 즐겨찾기에서 제거되었습니다."
                    DispatchQueue.main.async {
                        UIApplication.shared.windows.first?.makeToast(toastMessage)
                    }
                }
                return self.mutate(action: .loadFavorites)
            }
            return Observable.empty()

        case .filterFavorites(let rarity):
            let filteredCards = rarity == "All" ? currentState.favoriteCards : currentState.favoriteCards.filter { card in
                let cardRarity = card.toPokemonCard().rarity ?? ""
                return FilterHelper.filterRarities(rarity).contains(cardRarity)
            }

            return Observable.concat([
                Observable.just(Mutation.setSelectedRarity(rarity)),
                Observable.just(Mutation.setFilteredFavorites(filteredCards)),
                Observable.just(Mutation.reloadTableView)
            ])

        case .setFavorites(let favorites):
            return Observable.just(Mutation.setFavorites(favorites))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setFavorites(let favorites):
            newState.favoriteCards = favorites
            let filteredFavorites = filterFavorites(favorites, by: newState.selectedRarity)
            newState.filteredFavorites = filteredFavorites
            viewSubject.onNext(.reloadTableView)

        case .setSelectedRarity(let rarity):
            newState.selectedRarity = rarity
            let filteredFavorites = filterFavorites(newState.favoriteCards, by: rarity)
            newState.filteredFavorites = filteredFavorites

        case .setFilteredFavorites(let filteredFavorites):
            newState.filteredFavorites = filteredFavorites
        case .reloadTableView:
            print("FavoriteReactor - reloadTableView mutation") 
            break
        }

        return newState
    }

    private func filterFavorites(_ favorites: [RealmPokemonCard], by rarity: String) -> [RealmPokemonCard] {
           return rarity == "All" ? favorites : favorites.filter { card in
               card.rarity == rarity || FilterHelper.filterRarities(rarity).contains(card.rarity ?? "")
           }
       }
   }
