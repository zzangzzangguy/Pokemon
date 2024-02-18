//
//  CardListViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit

final class CardListViewController: BaseViewController {

    // MARK: - Properties

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .white
    }

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
