//
//  SearchReactor.swift
//  Pokemon
//
//  Created by 김기현 on 2/21/24.
//

import ReactorKit
import RxSwift

class SearchReactor: Reactor {
    let initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository
    }

    enum Action {
        case updateSearchQuery(String)
        case search
    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults(Result<[PokemonCard], Error>)
    }

    struct State {
        var query: String = ""
        var searchResult: Result<[PokemonCard], Error>?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return Observable.just(Mutation.setQuery(query))
        case .search:
            return searchQuery().map(Mutation.setSearchResults)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setQuery(let query):
            newState.query = query
        case .setSearchResults(let result):
            newState.searchResult = result
        }
        return newState
    }

    private func searchQuery() -> Observable<Result<[PokemonCard], Error>> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }

            let request = CardsRequest(query: self.currentState.query)
            self.pokemonRepository.fetchCards(request: request) { result in
                observer.onNext(result)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
