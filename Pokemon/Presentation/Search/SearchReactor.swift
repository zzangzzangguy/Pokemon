//
//  SearchReactor.swift
//  Pokemon
//
//  Created by 김기현 on 2/21/24.
//

import ReactorKit
import RxSwift

class SearchReactor: Reactor {
    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository
    }

    enum Action {
        case updateSearchQuery(String)
        case search(String)
        case loadMore
    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults(Result<[PokemonCard], Error>)
        case appendSearchResults(Result<[PokemonCard], Error>)
        case setLoading(Bool)
        case setPage(Int)
        case setCanLoadMore(Bool)
    }

    struct State {
        var query: String = ""
        var searchResult: Result<[PokemonCard], Error>?
        var isLoading: Bool = false
        var page: Int = 1
        var canLoadMore: Bool = true
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .just(.setQuery(query))

        case .search(let query):
            guard !query.isEmpty && !currentState.isLoading else {
                return .empty()
            }
            return Observable.concat([
                .just(.setQuery(query)),
                .just(.setLoading(true)),
                searchQuery(query: query, page: 1)
                    .map { result in
                        switch result {
                        case .success(let cards):
                            return Mutation.setSearchResults(.success(cards))
                        case .failure(let error):
                            return Mutation.setSearchResults(.failure(error))
                        }
                    },
                .just(.setLoading(false))
            ])

        case .loadMore:
            guard currentState.canLoadMore && !currentState.isLoading else {
                return .empty()
            }
            let nextPage = currentState.page + 1
            return Observable.concat([
                .just(.setLoading(true)),
                searchQuery(query: currentState.query, page: nextPage)
                    .map { result in
                        switch result {
                        case .success(let cards):
                            return Mutation.appendSearchResults(.success(cards))
                        case .failure(let error):
                            return Mutation.appendSearchResults(.failure(error))
                        }
                    },
                .just(.setLoading(false)),
                .just(.setPage(nextPage))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setQuery(let query):
            newState.query = query
            newState.searchResult = nil

        case .setSearchResults(let result):
            newState.searchResult = result
            newState.canLoadMore = true

        case .appendSearchResults(let result):
            switch (result, newState.searchResult) {
            case (.success(let newCards), .success(let currentCards)):
                newState.searchResult = .success(currentCards + newCards)
            case (.failure(let error), _):
                newState.searchResult = .failure(error)
                newState.canLoadMore = false
            default:
                break
            }

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setPage(let page):
            newState.page = page

        case .setCanLoadMore(let canLoadMore):
            newState.canLoadMore = canLoadMore
        }
        return newState
    }

    private func searchQuery(query: String, page: Int) -> Observable<Result<[PokemonCard], Error>> {
        guard !query.isEmpty else {
            return .just(.success([]))
        }

        let request = CardsRequest(query: query, page: page, pageSize: 5)
        return Observable.create { [weak self] observer in
            self?.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let pokemonCardsContainer):
                    observer.onNext(.success(pokemonCardsContainer.data))
                case .failure(let error):
                    observer.onNext(.failure(error))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
