//
//  CardListReactor.swift
//  Pokemon
//
//  Created by 강호성 on 2/19/24.
//

import ReactorKit
import RxCocoa
import RxSwift

final class CardListReactor: Reactor {

    // MARK: - Properties

    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setList([PokemonCard])
        case setError(Error)
    }

    struct State {
        var pokemonCards = BehaviorRelay<[PokemonCard]>(value: [])
        var error: Error?
    }

    let initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    // MARK: - Init

    init(pokemonRepository: PokemonRepositoryType = PokemonRepository()) {
        self.pokemonRepository = pokemonRepository
    }

    // MARK: - Helpers

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.create { [weak self] observer in
                guard let self = self else { return Disposables.create() }
                self.pokemonRepository.fetchCards(request: CardsRequest()) { result in
                    switch result {
                    case .success(let cards):
                        observer.onNext(.setList(cards.data))
                        observer.onCompleted()

                    case .failure(let error):
                        observer.onNext(.setError(error))
                        observer.onCompleted()
                    }
                }
                return Disposables.create()
            }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setList(let cards):
            newState.pokemonCards.accept(cards)

        case .setError(let error):
            newState.error = error
        }
        return newState
    }
}
