import UIKit

final class KivroHomeBackgroundView: UIView {
    private let radialLayer = CAGradientLayer()
    private let fadeLayer = CAGradientLayer()
    private let bannerView = UIImageView(image: UIImage(named: "kivro_home_banner"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        radialLayer.frame = bounds
        bannerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width * 0.78125)
        fadeLayer.frame = bounds
    }

    private func configureView() {
        backgroundColor = UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 1)

        radialLayer.type = .radial
        radialLayer.colors = [
            UIColor(red: 93 / 255, green: 70 / 255, blue: 130 / 255, alpha: 1).cgColor,
            UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 1).cgColor
        ]
        radialLayer.locations = [0, 1]
        radialLayer.startPoint = CGPoint(x: 0.68, y: 0.08)
        radialLayer.endPoint = CGPoint(x: 0.03, y: 1.0)
        layer.addSublayer(radialLayer)

        bannerView.contentMode = .scaleAspectFill
        bannerView.clipsToBounds = true
        addSubview(bannerView)

        fadeLayer.colors = [
            UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 0).cgColor,
            UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 1).cgColor
        ]
        fadeLayer.locations = [0.0821, 1]
        fadeLayer.startPoint = CGPoint(x: 0.5, y: 0.18)
        fadeLayer.endPoint = CGPoint(x: 0.5, y: 0.39)
        layer.addSublayer(fadeLayer)
    }
}
