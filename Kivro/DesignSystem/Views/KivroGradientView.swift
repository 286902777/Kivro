import UIKit

final class KivroGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func configureGradient() {
        gradientLayer.type = .radial
        gradientLayer.colors = [
            UIColor(red: 93 / 255, green: 70 / 255, blue: 130 / 255, alpha: 1).cgColor,
            UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 1.3, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.55, y: 0.55)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
