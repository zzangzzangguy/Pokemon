import ReactorKit
import RxSwift

class SearchReactor: Reactor {
    // MARK: - Properties

    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    // MARK: - Initialization

    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository
    }

    enum Action {
        case updateSearchQuery(String)
        case search(String)
        case loadNextPage
        case scrollTop
    }
    enum Mutation {
        case setQuery(String)
        case setSearchResults([PokemonCard])
        case appendSearchResults([PokemonCard])
        case setLoading(Bool)
        case setCanLoadMore(Bool)
        case setNoResults(Bool)
        case setScrollTop(Bool)
    }
    struct State {
        var query: String = ""
        var searchResult: [PokemonCard] = []
        var isLoading: Bool = false
        var canLoadMore: Bool = true
        var noResults: Bool = false
        var scrollTop: Bool = false
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .concat([
                .just(.setQuery(query)),
                .just(.setNoResults(false))
            ])

        case .search(let query):
            guard !query.isEmpty else {
                return .concat([
                    .just(.setLoading(false)),
                    .just(.setSearchResults([])),
                    .just(.setNoResults(true))
                ])
            }

            let initialPage = 1
            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: query, page: initialPage)
                    .map { results in
                        if results.isEmpty {
                            return .setNoResults(true)
                        } else {
                            return .setSearchResults(results)
                        }
                    },
                .just(.setLoading(false))
            ])
        case .loadNextPage:
            guard !currentState.isLoading, currentState.canLoadMore else {
                return .empty()
            }

            let nextPage = (currentState.searchResult.count / 20) + 1

            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: currentState.query, page: nextPage)
                    .map { .appendSearchResults($0) },
                .just(.setLoading(false)),
                .just(.setCanLoadMore(true))
            ])
        case .scrollTop:
            return .concat([
                .just(.setScrollTop(true)),
//                .just(.setScrollTop(false))
            ])
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

        }

        return newState
    }

    private func searchQuery(query: String, page: Int) -> Observable<[PokemonCard]> {
        let pageSize = 20
        let request = CardsRequest(query: query, page: page, pageSize: pageSize)

        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure:
                    observer.onNext([])
                }

                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
