//
//  SearchViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit

final class SearchViewController: BaseViewController {
    // MARK: - Properties
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var loadingIndicator: UIActivityIndicatorView!
    var reactor: SearchReactor?
    private var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>>?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initReactor()
        setView()
        setConstraints()
        setConfiguration()
    }

    private func initReactor() {
        self.reactor = SearchReactor(pokemonRepository: PokemonRepository())
        if let reactor = self.reactor {
            bind(reactor: reactor)
        }
    }

    private func bind(reactor: SearchReactor) {
        searchBar.rx.text.orEmpty
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { SearchReactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.searchResult }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let pokemonCards):
                    if pokemonCards.isEmpty {
                        self?.showNoResultsAlert()
                    } else {
                        let sectionModel = [SectionModel(model: "", items: pokemonCards)]
                        self?.dataSource?.setSections(sectionModel)
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers
    override func setView() {
        super.setView()

        searchBar.placeholder = " 포켓몬을 검색하세요!"
        navigationItem.titleView = searchBar
        searchBar.delegate = self

        tableView.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
        view.addSubview(tableView)

        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .black
        view.addSubview(loadingIndicator)
    }

    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()

        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setDataSource() {
        dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>>(
            configureCell: { [weak self] _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: PokemonCardTableViewCell.reuseIdentifier, for: indexPath) as! PokemonCardTableViewCell
                cell.configure(with: item)

                if let reactor = self?.reactor {
                    switch reactor.currentState.searchResult {
                    case .success(let pokemonCards):
                        if indexPath.row == pokemonCards.count - 1 {
                            reactor.action.onNext(.loadMore)
                        }
                    case .failure, .none:
                        break
                    }
                }

                return cell
            }
        )
    }

    private func showLoadingIndicator() {
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.isHidden = false
    }

    private func hideLoadingIndicator() {
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.isHidden = true
    }


    private func showNoResultsAlert() {
        if presentedViewController == nil {
            let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없습니다.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }

    private func showErrorAlert(message: String) {
        if presentedViewController == nil {
            let alertController = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }

    override func setConfiguration() {
        super.setConfiguration()
        setDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
//        tableView.rx.setDelegate(self).disposed(by: disposeBag)

    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else {
            return
        }
        reactor?.action.onNext(.search(query))
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let dataSource = self.dataSource else { return }

        let section = dataSource.sectionModels
        let itemsCount = section[indexPath.section].items.count
        if indexPath.row == itemsCount - 1, let reactor = self.reactor { 
            reactor.action.onNext(.loadMore)
        }
    }
}
