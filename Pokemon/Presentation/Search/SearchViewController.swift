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

final class SearchViewController: BaseViewController, ReactorKit.View  {
    // MARK: - Properties
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private lazy var loadingIndicator = UIActivityIndicatorView(style: .large)

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
        bindAction(reactor)
        bindState(reactor)
    }

    private func bindAction(_ reactor: SearchReactor) {
        searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { Reactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .map { self.searchBar.text ?? "" }
            .filter { !$0.isEmpty }
            .map { Reactor.Action.search($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let self = self else { return false }
                return offset.y + self.tableView.frame.height >= self.tableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadMore }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }

    private func bindState(_ reactor: SearchReactor) {
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.loadingIndicator.isHidden = !isLoading
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.searchResult }
            .compactMap { result -> [PokemonCard]? in
                switch result {
                case .success(let cards):
                    return cards
                case .failure, .none:
                    return nil
                }
            }
            .bind(to: tableView.rx.items(cellIdentifier: PokemonCardTableViewCell.reuseIdentifier, cellType: PokemonCardTableViewCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        reactor.state.map { $0.searchResult }
            .filter { $0 != nil }
            .map { result -> Bool in
                switch result {
                case .success(let cards):
                    return cards.isEmpty
                case .failure, .none:
                    return false
                }
            }
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showNoResultsAlert()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers
    override func setView() {
        super.setView()

        searchBar.placeholder = " 포켓몬을 검색하세요!"
        navigationItem.titleView = searchBar
        view.addSubview(tableView)

        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .black
        loadingIndicator.isHidden = true // 초기에 인디케이터 숨기기
        view.addSubview(loadingIndicator)
    }

    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func setConfiguration() {
        super.setConfiguration()
        tableView.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
        tableView.delegate = nil
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    private func showNoResultsAlert() {
        let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없습니다.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
