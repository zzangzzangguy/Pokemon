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
            print("Query: \(query)")
            return .just(.setQuery(query))

        case .search:
            print("Trigger")
            return searchQuery()
                .map { .setSearchResults($0) }
                .catch { error in .just(.setSearchResults(.failure(error))) }
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
        guard !currentState.query.isEmpty else {
            return .just(.success([]))
        }
        let parameters = ["q": currentState.query]
        print("검색 시작: \(currentState.query)")

        let request = CardsRequest(query: currentState.query)
        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                print("API 결과: \(result)")
                observer.onNext(result)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
