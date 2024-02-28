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
        case search
        case loadMore
    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults(Result<[PokemonCard], Error>)
        case appendSearchResults(Result<[PokemonCard], Error>)
        case setPage(Int)
        case setCanLoadMore(Bool)
    }

    struct State {
        var query: String = ""
        var searchResult: Result<[PokemonCard], Error>?
        var page: Int = 1
        var canLoadMore: Bool = true
    }


    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            print("Query: \(query)")
            return Observable.concat([
                .just(.setQuery(query)),
                .just(.setSearchResults(.success([])))
            ])

        case .search:
            return Observable.concat([
                .just(.setPage(1)),
                .just(.setCanLoadMore(true)),
                searchQuery(page: 1)
                    .map(Mutation.setSearchResults)
            ])
        case .loadMore:
            guard currentState.canLoadMore else {
                return .empty()
            }
            let nextPage = currentState.page + 1
            return searchQuery(page: nextPage)
                .map(Mutation.appendSearchResults)
                .startWith(.setPage(nextPage))
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
        case .appendSearchResults(let result):
            if case let .success(newCards) = result, case .success(var currentCards) = newState.searchResult {
                currentCards += newCards
                newState.searchResult = .success(currentCards)
            } else if case .failure = result {
                newState.canLoadMore = false
            }
        case .setPage(let page):
            newState.page = page
        case .setCanLoadMore(let canLoadMore):
            newState.canLoadMore = canLoadMore
        }
        return newState
    }

    private func searchQuery(page: Int) -> Observable<Result<[PokemonCard], Error>> {
        guard !currentState.query.isEmpty else {
            return .just(.success([]))
        }

        let request = CardsRequest(query: currentState.query, page: page, pageSize: 20) 
        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                observer.onNext(result)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
