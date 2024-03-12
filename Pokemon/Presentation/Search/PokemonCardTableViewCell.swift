//
//  PokemonCardTableViewCell.swift
//  Pokemon
//
//  Created by 김기현 on 2/24/24.
//

import UIKit
import Kingfisher
import Then
import SnapKit

class PokemonCardTableViewCell: UITableViewCell {
    let cardImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }

    let hpLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .red
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    private func setupView() {
        self.contentView.addSubview(cardImageView)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(hpLabel)
    }

    private func setupLayout() {
        cardImageView.snp.makeConstraints {
            $0.top.left.equalToSuperview().offset(10)
            $0.width.height.equalTo(150)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(cardImageView.snp.trailing).offset(10) 
            $0.trailing.equalToSuperview().inset(10)
        }
        hpLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel.snp.leading)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.kf.cancelDownloadTask()
        cardImageView.image = nil
        nameLabel.text = nil
    }

    func configure(with card: PokemonCard) {
        nameLabel.text = card.name
        if let hp = card.hp {
                 hpLabel.text = "HP: \(hp)"
             } else {
                 hpLabel.text = "HP: -"
             }
        
        print("이미지 URL: \(card.images.small.absoluteString)")
        cardImageView.kf.setImage(with: card.images.small, placeholder: UIImage(named: "placeholder"), options: [.transition(.fade(1))], completionHandler:  { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    print("이미지 로드 성공: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("이미지 로드 실패: \(error.localizedDescription)")
                }
            }
        })
    }
}
