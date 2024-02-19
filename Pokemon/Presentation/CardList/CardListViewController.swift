//
//  CardListViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import RxDataSources

final class CardListViewController: BaseViewController {

    // MARK: - Properties

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .white
        $0.contentInset = .init(top: 16, left: 16, bottom: 40, right: 16)
        $0.delegate = self
        $0.register(
            CardListCollectionViewCell.self,
            forCellWithReuseIdentifier: CardListCollectionViewCell.reuseIdentifier
        )
    }

    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<CardListSection.CardListSectionModel>(
        configureCell: { [weak self] dataSource, collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }
            switch item {
            case .firstItem(let value):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CardListCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as! CardListCollectionViewCell
                return cell
            }
        }
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Helpers

    override func setView() {
        super.setView()
        view.addSubview(collectionView)
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
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CardListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        let width = collectionView.bounds.width - 32
        let itemWidth = (width - 16) / 2
        let itemHeight: CGFloat = 200

        return CGSize(width: itemWidth, height: itemHeight)
    }
}
