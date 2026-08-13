import UIKit
import SnapKit

final class KivroVoiceRecordingView: UIView {
    private let durationLabel = UILabel()
    private let bars: [UIView] = (0..<5).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    func updateDuration(_ duration: TimeInterval) {
        durationLabel.text = String(format: "Recording  %.1fs", duration)
    }

    func presentAnimated() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.78, y: 0.78)
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.7
        ) {
            self.alpha = 1
            self.transform = .identity
        }
        startBarAnimations()
    }

    func dismissAnimated(completion: (() -> Void)? = nil) {
        bars.forEach { $0.layer.removeAllAnimations() }
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    private func configureView() {
        backgroundColor = UIColor(red: 33 / 255, green: 23 / 255, blue: 43 / 255, alpha: 0.94)
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor

        let barsStack = UIStackView(arrangedSubviews: bars)
        barsStack.axis = .horizontal
        barsStack.alignment = .center
        barsStack.distribution = .equalSpacing
        barsStack.spacing = 7
        addSubview(barsStack)
        barsStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(37)
            make.width.equalTo(82)
            make.height.equalTo(50)
        }

        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = UIColor(red: 112 / 255, green: 91 / 255, blue: 1, alpha: 1)
            bar.layer.cornerRadius = 3
            bar.snp.makeConstraints { make in
                make.width.equalTo(6)
                make.height.equalTo(18 + CGFloat(index % 3) * 8)
            }
        }

        durationLabel.text = "Recording  0.0s"
        durationLabel.textColor = .white
        durationLabel.font = KivroTypography.inter(size: 14, weight: .bold)
        durationLabel.textAlignment = .center
        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(barsStack.snp.bottom).offset(13)
        }

        let hintLabel = UILabel()
        hintLabel.text = "Release to send"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        hintLabel.font = KivroTypography.inter(size: 11, weight: .medium)
        hintLabel.textAlignment = .center
        addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(durationLabel.snp.bottom).offset(7)
        }
    }

    private func startBarAnimations() {
        for (index, bar) in bars.enumerated() {
            UIView.animate(
                withDuration: 0.32 + Double(index) * 0.06,
                delay: Double(index) * 0.04,
                options: [.autoreverse, .repeat, .allowUserInteraction]
            ) {
                bar.transform = CGAffineTransform(scaleX: 1, y: index.isMultiple(of: 2) ? 1.8 : 0.55)
                bar.alpha = 0.55
            }
        }
    }
}
