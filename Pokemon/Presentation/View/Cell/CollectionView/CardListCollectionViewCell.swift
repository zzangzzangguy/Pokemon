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

    // MARK: - Helpers

    override func setView() {
        super.setView()
        contentView.addSubview(imageView)
        contentView.addSubview(hpTextLabel)
        contentView.addSubview(nameLabel)
    }

    override func setConstraints() {
        super.setConstraints()
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        hpTextLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(hpTextLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
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
