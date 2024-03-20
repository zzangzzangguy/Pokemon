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
    }

    struct State {
        var query: String = ""
        var searchResult: [PokemonCard] = []
        var isLoading: Bool = false
        var canLoadMore: Bool = true
        var noResults: Bool = false
        var scrollTop: Bool = false
        var favorites: [String] = []
        var selectedItem: PokemonCard?
        var selectedRarity: String = "All"
        var page: Int = 1
        var pageSize: Int = 20
        var error: Error?
    }

    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    // MARK: - Initialization
    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository

        let favoriteCardIDs = RealmManager.shared.getFavoriteCardIDs()
        initialState = State(favorites: favoriteCardIDs)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .concat([
                .just(.setQuery(query)),
                .just(.setNoResults(false))
            ])

        case .search(let query):
            let initialPage = 1

            if currentState.selectedRarity == "All" {
                return .concat([
                    .just(.setLoading(true)),
                    .just(.setNoResults(false)),
                    searchQuery(query: query, page: initialPage, rarity: nil)
                        .map { results in
                            if results.isEmpty {
                                return .setNoResults(true)
                            } else {
                                return .setSearchResults(results)
                            }
                        }
                        .catch { .just(.setError($0)) },
                    .just(.setLoading(false))
                ])
            } else if query.isEmpty {
                return .concat([
                    .just(.setLoading(false)),
                    .just(.setSearchResults([])),
                    .just(.setNoResults(true))
                ])
            } else {
                return .concat([
                    .just(.setLoading(true)),
                    .just(.setNoResults(false)),
                    searchQuery(query: query, page: initialPage, rarity: currentState.selectedRarity)
                        .map { results in
                            if results.isEmpty {
                                return .setNoResults(true)
                            } else {
                                return .setSearchResults(results)
                            }
                        }
                        .catch { .just(.setError($0)) },
                    .just(.setLoading(false))
                ])
            }

        case .loadNextPage:
            guard !currentState.isLoading, currentState.canLoadMore else {
                return .empty()
            }

            let nextPage = currentState.page + 1

            return .concat([
                .just(.setLoading(true)),
                .just(.setPage(nextPage)),
                searchQuery(query: currentState.query, page: nextPage, rarity: currentState.selectedRarity)
                    .map { .appendSearchResults($0) },
                .just(.setLoading(false)),
                .just(.setCanLoadMore(true))
            ])

        case .scrollTop:
            return .concat([
                .just(.setScrollTop(true)),
                .just(.setScrollTop(false))
            ])

        case .updateFavoriteStatus(let cardID, let isFavorite):
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                RealmManager.shared.updateFavorite(for: cardID, isFavorite: isFavorite)
                observer.onNext(Mutation.setFavorite(cardID, isFavorite))
                observer.onCompleted()
                return Disposables.create()
            }
        case .selectItem(let card):
            return Observable.just(Mutation.setSelectedItem(card))
        case .selectRarity(let rarity):
            return Observable.concat([
                .just(Mutation.setSelectedRarity(rarity)),
                searchQuery(query: currentState.query, page: 1, rarity: rarity)
                    .map(Mutation.setSearchResults)
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

        case .setFavorite(let cardID, let isFavorite):
            if isFavorite {
                newState.favorites.append(cardID)
            } else {
                if let index = newState.favorites.firstIndex(of: cardID) {
                    newState.favorites.remove(at: index)
                }
            }

        case .setSelectedItem(let item):
            newState.selectedItem = item
        case .setSelectedRarity(let rarity):
            newState.selectedRarity = rarity

        case .setError(let error):
            newState.error = error
        case .setPage(let page):
            newState.page = page
        }
        return newState
    }

    private func searchQuery(query: String, page: Int, rarity: String?) -> Observable<[PokemonCard]> {
        let pageSize = 20
        let request = CardsRequest(query: query, page: page, pageSize: pageSize, rarity: rarity)

        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let response):
                    observer.onNext(response.data)
                    print("ㅇㅇ\(response.data)")
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
