import UIKit

final class KivroGradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2
    }

    private func configure() {
        titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
        setTitleColor(.black, for: .normal)
        gradientLayer.colors = [
            UIColor(red: 243 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1).cgColor,
            UIColor(red: 167 / 255, green: 161 / 255, blue: 231 / 255, alpha: 1).cgColor,
            UIColor(red: 231 / 255, green: 231 / 255, blue: 247 / 255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.4694, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
