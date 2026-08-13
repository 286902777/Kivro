import UIKit

final class KivroPersonaUploadCardView: UIView {
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
        gradientLayer.cornerRadius = 29
    }

    private func configureGradient() {
        gradientLayer.colors = [
            UIColor(red: 217 / 255, green: 155 / 255, blue: 249 / 255, alpha: 1).cgColor,
            UIColor(red: 219 / 255, green: 246 / 255, blue: 251 / 255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
