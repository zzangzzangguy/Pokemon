//
//  CardListViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import RxDataSources
import ReactorKit

final class CardListViewController: BaseViewController, ReactorKit.View {

    // MARK: - Properties

    private let indicatorView = UIActivityIndicatorView(
        frame: CGRect(x: 0, y: 0, width: 50, height: 50)
    ).then {
        $0.color = .black
        $0.style = .large
    }
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .white
        $0.contentInset = .init(top: 16, left: 16, bottom: 40, right: 16)
        $0.register(
            CardListCollectionViewCell.self,
            forCellWithReuseIdentifier: CardListCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Init

    required init(reactor: CardListReactor) {
        defer { self.reactor = reactor }
        super.init()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Helpers

    override func setView() {
        super.setView()
        view.addSubview(collectionView)
        view.addSubview(indicatorView)
    }

    override func setConstraints() {
        super.setConstraints()
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setConfiguration() {
        super.setConfiguration()
        title = "카드 리스트"

        collectionView.delegate = self
        indicatorView.center = view.center
    }

    func bind(reactor: CardListReactor) {
        self.rx.viewDidLoad
          .map { Reactor.Action.viewDidLoad }
          .bind(to: reactor.action)
          .disposed(by: disposeBag)

        let dataSource = RxCollectionViewSectionedReloadDataSource<CardListSection.CardListSectionModel>(
            configureCell: { dataSource, collectionView, indexPath, item in

                switch item {
                case .firstItem(let value):
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: CardListCollectionViewCell.reuseIdentifier,
                        for: indexPath
                    ) as! CardListCollectionViewCell
                    cell.bind(value)
                    return cell
                }
            }
        )

        reactor.state.map { $0.pokemonCards.value }
            .asDriver(onErrorJustReturn: [])
            .map { value in
                return [CardListSection.CardListSectionModel(
                    model: 0,
                    items: value.map { .firstItem($0) }
                )]
            }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading ?? false }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self = self else { return }

                if isLoading {
                    self.indicatorView.startAnimating()
                } else {
                    self.indicatorView.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CardListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        let width = (collectionView.bounds.width - 56) / 3
        let itemHeight: CGFloat = 220

        return CGSize(width: width, height: itemHeight)
    }
}
