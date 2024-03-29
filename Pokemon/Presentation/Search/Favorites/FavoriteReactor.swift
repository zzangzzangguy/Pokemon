//
//  FavoriteReactor.swift
//  Pokemon
//
//  Created by 김기현 on 3/21/24.
//
import ReactorKit
import RxSwift
import RealmSwift

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

    enum Mutation {
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

        AppState.shared.favoriteStatusChanged
            .observe(on: MainScheduler.instance)
            .flatMap { _ in Observable.just(Action.loadFavorites) }
            .bind(to: self.action)
            .disposed(by: disposeBag)
    }



    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadFavorites:
            let favorites = Array(RealmManager.shared.getFavoriteCards())
            return Observable.just(Mutation.setFavorites(favorites))

        case .toggleFavorite(let cardID, let isFavorite):
            if let card = currentState.favoriteCards.first(where: { $0.id == cardID })?.toPokemonCard() {
                RealmManager.shared.updateFavorite(for: cardID, with: card, isFavorite: isFavorite)
                if let updatedCard = RealmManager.shared.getCard(withId: cardID)?.toPokemonCard() {
                    print("즐겨찾기 상태 변경됨 - 이름: \(updatedCard.name), 타입: \(updatedCard.types?.joined(separator: ", ") ?? "-"), 등급: \(updatedCard.rarity ?? "-"), HP: \(updatedCard.hp ?? "-")")
                }
            }
            let favorites = Array(RealmManager.shared.getFavoriteCards())
            return .concat([
                .just(.setFavorites(favorites)),
                .just(.reloadTableView)
            ])

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
            viewSubject.onNext(.reloadTableView)
        case .setSelectedRarity(let rarity):
            newState.selectedRarity = rarity
        case .setFilteredFavorites(let filteredFavorites):
            newState.filteredFavorites = filteredFavorites
        case .reloadTableView:
            break
        }

        return newState
    }
}
