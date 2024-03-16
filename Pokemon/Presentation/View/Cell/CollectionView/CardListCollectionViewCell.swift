//
//  CardListCollectionViewCell.swift
//  Pokemon
//
//  Created by 강호성 on 2/18/24.
//

import UIKit
import Kingfisher

final class CardListCollectionViewCell: BaseCollectionViewCell<PokemonCard> {

    // MARK: - Properties

    private let imageView = UIImageView().then {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFit
    }
    private let hpTextLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .blue
    }
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .black
    }
    private let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "star"), for: .normal)
        $0.setImage(UIImage(systemName: "star.fill"), for: .selected)
        $0.tintColor = .systemYellow
    }

    // MARK: - Helpers

    override func setView() {
        super.setView()
        contentView.addSubview(imageView)
        contentView.addSubview(hpTextLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(favoriteButton)
    }

    override func setConstraints() {
        super.setConstraints()
        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        hpTextLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(hpTextLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview()
        }
        favoriteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.right.equalToSuperview().inset(10)
            $0.width.height.equalTo(30)
        }
    }

override func bind(_ model: PokemonCard?) {
    super.bind(model)

    imageView.kf.setImage(
        with: model?.images.large,
        options: [.transition(.fade(1))]
    )
    nameLabel.text = model?.name ?? ""
    hpTextLabel.text = "hp \(model?.hp ?? "")"
}
}
