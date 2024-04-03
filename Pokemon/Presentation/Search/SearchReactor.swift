//
//  SearchReactor.swift
//  Pokemon
//
//  Created by 김기현 on 2/15/24.
//

import ReactorKit
import RxSwift
import RealmSwift
import Realm

class SearchReactor: Reactor {
    enum Action {
        case updateSearchQuery(String)
        case search(String)
        case loadNextPage
        case scrollTop
        case updateFavoriteStatus(String, Bool)
        case selectItem(PokemonCard)
        case selectRarity(String)
        case loadFavorites
    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults([PokemonCard])
        case appendSearchResults([PokemonCard])
        case setLoading(Bool)
        case setCanLoadMore(Bool)
        case setNoResults(Bool)
        case setScrollTop(Bool)
        case setFavorite(String, Bool)
        case setSelectedItem(PokemonCard?)
        case setSelectedRarity(String)
        case setError(Error?)
        case setPage(Int)
        case setFavorites([RealmPokemonCard])
        case resetPagination(page: Int, pageSize: Int)
    }

    struct State {
        var query: String = ""
        var searchResult: [PokemonCard] = []
        var isLoading: Bool = false
        var canLoadMore: Bool = true
        var noResults: Bool = false
        var scrollTop: Bool = false
        var favorites: [RealmPokemonCard] = []
        var selectedItem: PokemonCard?
        var selectedRarity: String = "All"
        var page: Int = 1
        var pageSize: Int = 10
        var error: Error?
        var currentPage: Int = 1
        var totalPages: Int = 1
    }

    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType
    private let disposeBag = DisposeBag()

    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository

        let favoriteCards = Array(RealmManager.shared.getFavoriteCards())
        initialState = State(favorites: favoriteCards)

        AppState.shared.favoriteStatusChanged
            .map { cardID in
                if let index = self.currentState.searchResult.firstIndex(where: { $0.id == cardID }) {
                    let updatedCard = self.currentState.searchResult[index]
                    let isFavorite = RealmManager.shared.getCard(withId: cardID)?.isFavorite ?? false
                    return Action.updateFavoriteStatus(updatedCard.id, isFavorite)
                }
                return Action.loadFavorites
            }
            .bind(to: action)
            .disposed(by: disposeBag)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .concat([
                .just(.setQuery(query)),
                .just(.setNoResults(false))
            ])

        case .search(var query):
            let initialPage = 1
            let rarity = currentState.selectedRarity == "All" ? nil : currentState.selectedRarity

            if !query.contains("select=") {
                query += "&select=id,name,images"
            }


            return .concat([
                .just(.setLoading(true)),
                .just(.setNoResults(false)),
                .just(.resetPagination(page: initialPage, pageSize: initialState.pageSize)),
                searchQuery(query: query, page: initialPage, rarity: rarity)
                    .map { response in
                        if response.data.isEmpty {
                            return .setNoResults(true)
                        } else {
                            return .setSearchResults(response.data)
                        }
                    }
                    .catch { .just(.setError($0)) },
                .just(.setLoading(false))
            ])

        case .loadNextPage:
            guard !currentState.isLoading else {
                return .empty()
            }

            let nextPage = currentState.page + 1
            let query = currentState.query
            let rarity = currentState.selectedRarity == "All" ? nil : currentState.selectedRarity

            return .concat([
                .just(.setLoading(true)),
                .just(.setPage(nextPage)),
                searchQuery(query: query, page: nextPage, rarity: rarity)
                    .map { response in
                        let oldData = self.currentState.searchResult
                        let newData = oldData + response.data
                        return .setSearchResults(newData)
                    }
                    .catch { .just(.setError($0)) },
                .just(.setLoading(false))
            ])
        case .scrollTop:
            return .concat([
                .just(.setScrollTop(true)),
                .just(.setScrollTop(false))
            ])

        case .updateFavoriteStatus(let cardID, let isFavorite):
            if let card = currentState.searchResult.first(where: { $0.id == cardID }) {
                RealmManager.shared.updateFavorite(for: cardID, with: card, isFavorite: isFavorite)

                if let updatedCard = RealmManager.shared.getCard(withId: cardID)?.toPokemonCard() {
                    print("카드 이름: \(updatedCard.name), HP: \(updatedCard.hp ?? "-"), 타입: \(updatedCard.types?.joined(separator: ", ") ?? "-"), 등급: \(updatedCard.rarity ?? "-")")
                }
            }

            let favorites = Array(RealmManager.shared.getFavoriteCards())
            return Observable.just(Mutation.setFavorites(favorites))
                .observe(on: MainScheduler.asyncInstance)

        case .selectItem(let card):
            return Observable.just(Mutation.setSelectedItem(card))

        case .selectRarity(let rarity):
            let searchRarity = rarity == "All" ? nil : rarity
            let query = currentState.query

            return Observable.concat([
                .just(.setLoading(true)),
                searchQuery(query: query, page: 1, rarity: searchRarity)
                    .map { response in
                            .setSearchResults(response.data)
                    }
                    .catch { error in
                            .just(.setError(error))
                    },
                .just(.setLoading(false))
            ])

        case .loadFavorites:
            let favorites = Array(RealmManager.shared.getFavoriteCards())

            return Observable.just(Mutation.setFavorites(favorites))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setQuery(let query):
            newState.query = query

        case .setSearchResults(let result):
            newState.searchResult = result
            newState.canLoadMore = true

        case .appendSearchResults(let results):
            newState.searchResult += results

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setCanLoadMore(let canLoadMore):
            newState.canLoadMore = canLoadMore

        case .setNoResults(let noResults):
            newState.noResults = noResults

        case .setScrollTop(let scrollToTop):
            newState.scrollTop = scrollToTop

        case .setFavorite(let cardID, let isFavorite):
            if isFavorite {
                if let card = RealmManager.shared.getCard(withId: cardID) {
                    newState.favorites.append(card)
                }
            } else {
                newState.favorites.removeAll { $0.id == cardID }
            }

        case .setSelectedItem(let item):
            newState.selectedItem = item
        case .setSelectedRarity(let rarity):
            newState.selectedRarity = rarity

        case .setError(let error):
            newState.error = error
        case .setPage(let page):
            newState.page = page
        case .setFavorites(let favorites):
            newState.favorites = favorites
        case .resetPagination(let page, let pageSize):
            newState.page = page
            newState.pageSize = pageSize
            newState.searchResult = []
        }
        return newState
    }

    private func searchQuery(query: String?, page: Int, rarity: String?) -> Observable<PokemonCards> {
        var request = CardsRequest(query: query, page: page, pageSize: currentState.pageSize, rarity: rarity)

        if let query = query {
            request.select = "id,name,images,hp,types,rarity"
        }

        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let response):
                    let loadedCount = response.data.count
                    let pageSize = response.pageSize
                    let canLoadMore = loadedCount == pageSize
                    observer.onNext(response)
                    print("Page \(response.page) loaded with \(loadedCount) items, pageSize: \(pageSize), canLoadMore: \(canLoadMore)")
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func filterRarities(_ selectedRarity: String) -> [String] {
        return FilterHelper.filterRarities(selectedRarity)
    }
}
