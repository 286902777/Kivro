import UIKit
import SnapKit

enum KivroToastPresenter {
    static func show(message: String, in view: UIView) {
        view.subviews.compactMap { $0 as? KivroToastView }.forEach { $0.removeFromSuperview() }
        let toast = KivroToastView(message: message)
        toast.alpha = 0
        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(28)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }
        UIView.animate(withDuration: 0.2) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.2, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
