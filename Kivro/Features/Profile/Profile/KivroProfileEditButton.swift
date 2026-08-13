import UIKit

final class KivroProfileEditButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureButton()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 16
    }

    private func configureButton() {
        titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
        setTitleColor(UIColor(red: 27 / 255, green: 18 / 255, blue: 31 / 255, alpha: 1), for: .normal)
        gradientLayer.colors = [
            UIColor(red: 189 / 255, green: 151 / 255, blue: 241 / 255, alpha: 1).cgColor,
            UIColor(red: 225 / 255, green: 188 / 255, blue: 237 / 255, alpha: 1).cgColor,
            UIColor(red: 245 / 255, green: 223 / 255, blue: 243 / 255, alpha: 1).cgColor,
            UIColor(red: 222 / 255, green: 244 / 255, blue: 252 / 255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.36, 0.64, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
