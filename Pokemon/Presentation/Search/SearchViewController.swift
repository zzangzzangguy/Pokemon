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

final class SearchViewController: BaseViewController, ReactorKit.View {
    // MARK: - Properties
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .black
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization
    required init(reactor: SearchReactor) {
        super.init()
        self.reactor = reactor
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
    }

    // MARK: - Binding
    func bind(reactor: SearchReactor) {
        // Action
        searchController.searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { Reactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.searchButtonClicked
            .withLatestFrom(searchController.searchBar.rx.text.orEmpty)
            .filter { !$0.isEmpty }
            .map { Reactor.Action.search($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let self = self else { return false }
                return offset.y + self.tableView.frame.height >= self.tableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)

        reactor.state.map { $0.searchResult }
            .bind(to: tableView.rx.items(cellIdentifier: PokemonCardTableViewCell.reuseIdentifier, cellType: PokemonCardTableViewCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        reactor.state.map { $0.searchResult.isEmpty }
                .distinctUntilChanged()
                .filter { $0 }
                .subscribe(onNext: { [weak self] _ in
                    self?.searchController.searchBar.resignFirstResponder()
                    self?.showNoResultsAlert()
                })
                .disposed(by: disposeBag)
        }

    // MARK: - Helpers
    override func setView() {
        super.setView()

        searchController.searchBar.placeholder = " 포켓몬을 검색하세요!"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController

        tableView.delegate = nil
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
    }

    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func setConfiguration() {
        super.setConfiguration()
        tableView.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    private func showNoResultsAlert() {
        let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없습니다.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
