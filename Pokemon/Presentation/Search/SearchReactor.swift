//
//  SearchReactor.swift
//  Pokemon
//
//  Created by 김기현 on 2/21/24.
//

import ReactorKit
import RxSwift

class SearchReactor: Reactor {
    enum Action {
        case updateSearchQuery(String)
        case search
        case cancel
    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults([PokemonCard])
        case setLoading(Bool)
        case setError(Error)
    }

    struct State {
        var query: String = ""
        var searchResults: [PokemonCard] = []
        var isLoading: Bool = false
        var error: Error?
    }

    let initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    init(pokemonRepository: PokemonRepositoryType) {
          self.pokemonRepository = pokemonRepository
      }


    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return Observable.just(Mutation.setQuery(query))

        case .search:
            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                searchQuery().map(Mutation.setSearchResults),
                Observable.just(Mutation.setLoading(false))
            ]).catchError { Observable.just(Mutation.setError($0)) }

        case .cancel:
            return .empty()
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setQuery(let query):
            newState.query = query

        case .setSearchResults(let results):
            newState.searchResults = results

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error
        }
        return newState
    }

    private func searchQuery() -> Observable<[PokemonCard]> {
        
        return Observable.create { [weak self] observer in
                   guard let self = self else { return Disposables.create() }

                   let request = CardsRequest(query: self.currentState.query)
                   self.pokemonRepository.fetchCards(request: request) { result in
                       switch result {
                       case .success(let data):
                           observer.onNext(data)
                           observer.onCompleted()
                       case .failure(let error):
                           observer.onError(error)
                       }
                   }

                   return Disposables.create()
               }
           }
       }
