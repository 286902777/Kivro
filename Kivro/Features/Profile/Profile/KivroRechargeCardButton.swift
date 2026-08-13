import UIKit

final class KivroRechargeCardButton: UIButton {
    private let backgroundShapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundShapeLayer.frame = bounds
        backgroundShapeLayer.path = makeBackgroundPath(in: bounds).cgPath
    }

    private func configureAppearance() {
        backgroundColor = .clear
        backgroundShapeLayer.fillColor = UIColor(
            red: 73 / 255,
            green: 33 / 255,
            blue: 76 / 255,
            alpha: 1
        ).cgColor
        backgroundShapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        backgroundShapeLayer.lineWidth = 1
        layer.insertSublayer(backgroundShapeLayer, at: 0)
    }

    private func makeBackgroundPath(in rect: CGRect) -> UIBezierPath {
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 23
        let sideBottom = height - 26

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: sideBottom))
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            controlPoint: CGPoint(x: 0, y: 0)
        )
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: width, y: cornerRadius),
            controlPoint: CGPoint(x: width, y: 0)
        )
        path.addLine(to: CGPoint(x: width, y: sideBottom))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: sideBottom),
            controlPoint: CGPoint(x: width / 2, y: height + 26)
        )
        path.close()
        return path
    }
}
