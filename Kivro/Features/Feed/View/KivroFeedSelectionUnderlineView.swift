import UIKit

final class KivroFeedSelectionUnderlineView: UIView {
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 1, y: 1))
        path.addCurve(
            to: CGPoint(x: rect.width - 1, y: 1),
            controlPoint1: CGPoint(x: rect.width * 0.28, y: rect.height),
            controlPoint2: CGPoint(x: rect.width * 0.72, y: rect.height)
        )
        path.lineWidth = 3
        path.lineCapStyle = .round
        UIColor.white.setStroke()
        path.stroke()
    }
}
