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
        case loadNextPage
    }

    enum Mutation {
        case setLoading(Bool)
        case setList([PokemonCard])
        case setError(Error)
    }

    struct State {
        var isLoading: Bool = false
        let pokemonCards = BehaviorRelay<[PokemonCard]>(value: [])
        var error: Error?
    }

    let initialState = State()

    private var request = CardsRequest()
    private let pokemonRepository: PokemonRepositoryType

    // MARK: - Init

    init(pokemonRepository: PokemonRepositoryType = PokemonRepository()) {
        self.pokemonRepository = pokemonRepository
    }

    // MARK: - Helpers

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                Observable.create { [weak self] observer in
                    guard let self = self else { return Disposables.create() }

                    self.pokemonRepository.fetchCards(request: self.request) { result in
                        switch result {
                        case .success(let cards):
                            observer.onNext(.setList(cards.data))
                        case .failure(let error):
                            observer.onNext(.setError(error))
                        }

                        observer.onCompleted()
                    }
                    return Disposables.create()
                },
                Observable.just(Mutation.setLoading(false))
            ])

        case .loadNextPage:
            guard !currentState.isLoading else { return Observable.empty() }

            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                Observable.create { [weak self] observer in
                    guard let self = self else { return Disposables.create() }

                    if var page = request.page {
                        page += 1
                        self.request.page = page
                    }

                    self.pokemonRepository.fetchCards(request: self.request) { [weak self] result in
                        guard let self = self else { return }

                        switch result {
                        case .success(let cards):
                            let oldDatas = self.currentState.pokemonCards.value
                            observer.onNext(.setList(oldDatas + cards.data))

                        case .failure(let error):
                            observer.onNext(.setError(error))
                        }

                        observer.onCompleted()
                    }
                    return Disposables.create()
                },
                Observable.just(Mutation.setLoading(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setList(let cards):
            newState.pokemonCards.accept(cards)

        case .setError(let error):
            newState.error = error
        }
        return newState
    }
}
