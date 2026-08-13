import UIKit
import SnapKit

final class RechargePackageCell: UICollectionViewCell {
    static let reuseIdentifier = "RechargePackageCell"

    private let topPanel = UIView()
    private let coinImageView = UIImageView(image: UIImage(named: "kivro_coin_badge"))
    private let amountLabel = UILabel()
    private let priceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = KivroPalette.lavender
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.black.withAlphaComponent(0.35).cgColor

        topPanel.backgroundColor = UIColor(red: 76 / 255, green: 30 / 255, blue: 73 / 255, alpha: 1)
        coinImageView.contentMode = .scaleAspectFit
        amountLabel.textAlignment = .center
        amountLabel.textColor = .black
        amountLabel.font = KivroTypography.inter(size: 20, weight: .black)
        priceLabel.textAlignment = .center
        priceLabel.textColor = .white
        priceLabel.backgroundColor = UIColor(red: 139 / 255, green: 126 / 255, blue: 178 / 255, alpha: 1)
        priceLabel.layer.cornerRadius = 8
        priceLabel.clipsToBounds = true
        priceLabel.font = KivroTypography.inter(size: 9, weight: .bold)

        [topPanel, amountLabel, priceLabel].forEach(contentView.addSubview)
        topPanel.addSubview(coinImageView)
        topPanel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(57)
        }
        coinImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(52)
        }
        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(topPanel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    func configure(with package: CoinPackage) {
        amountLabel.text = String(package.coinAmount)
        priceLabel.text = KivroStrings.value(package.displayPriceKey)
    }
}
