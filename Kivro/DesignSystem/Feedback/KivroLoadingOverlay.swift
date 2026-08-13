import UIKit
import SnapKit

final class KivroLoadingOverlay: UIView {
    private let indicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.46)
        isUserInteractionEnabled = true
        indicator.color = .white
        addSubview(indicator)
        indicator.snp.makeConstraints { make in make.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    func show(in view: UIView) {
        guard superview == nil else { return }
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        indicator.startAnimating()
    }

    func hide() {
        indicator.stopAnimating()
        removeFromSuperview()
    }
}
