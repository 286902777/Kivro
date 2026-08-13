import UIKit
import SnapKit

final class ReportViewController: KivroViewController {
    private let loadingOverlay = KivroLoadingOverlay()
    private let reportButton = KivroGradientButton()
    private let reasons = [
        "POLITICALLY SENSITIVE",
        "BLOODY VIOLENCE",
        "FREQUENT HARASSMENT",
        "INFRINGEMENT OF RIGHTS",
        "PORNOGRAPHIC AND VULGAR",
        "DISCRIMINATION",
        "OTHERS"
    ]
    private var reasonButtons: [KivroReportReasonButton] = []
    private var selectedReason = 0
    private var isSubmitting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = KivroPageHeaderView(title: "Report")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        for (index, reason) in reasons.enumerated() {
            let button = KivroReportReasonButton()
            button.tag = index
            button.setTitle(reason, for: .normal)
            button.titleLabel?.font = KivroTypography.inter(size: 14, weight: .bold)
            button.isSelected = index == selectedReason
            button.addTarget(self, action: #selector(selectReason(_:)), for: .touchUpInside)
            reasonButtons.append(button)
            view.addSubview(button)
            button.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.top.equalToSuperview().offset(134 + CGFloat(index * 79))
                make.height.equalTo(54)
            }
        }

        reportButton.setTitle("REPORT", for: .normal)
        reportButton.addTarget(self, action: #selector(submitReport), for: .touchUpInside)
        view.addSubview(reportButton)
        reportButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.top.equalToSuperview().offset(703)
            make.height.equalTo(60)
        }
    }

    @objc private func selectReason(_ sender: UIButton) {
        selectedReason = sender.tag
        for button in reasonButtons {
            button.isSelected = button.tag == selectedReason
        }
    }

    @objc private func submitReport() {
        guard !isSubmitting else { return }
        isSubmitting = true
        reportButton.isEnabled = false
        loadingOverlay.show(in: view)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            loadingOverlay.hide()
            reportButton.isEnabled = true
            isSubmitting = false
            KivroToastPresenter.show(message: "Report submitted.", in: view)
        }
    }
}

private final class KivroReportReasonButton: UIButton {
    private let selectedGradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.7 : 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectedGradientLayer.frame = bounds
        selectedGradientLayer.cornerRadius = layer.cornerRadius
    }

    private func configureAppearance() {
        layer.cornerRadius = 14
        layer.masksToBounds = true
        selectedGradientLayer.colors = [
            UIColor(red: 229 / 255, green: 242 / 255, blue: 250 / 255, alpha: 1).cgColor,
            UIColor(red: 205 / 255, green: 155 / 255, blue: 239 / 255, alpha: 1).cgColor
        ]
        selectedGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        selectedGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(selectedGradientLayer, at: 0)
        updateAppearance()
    }

    private func updateAppearance() {
        selectedGradientLayer.isHidden = !isSelected
        layer.borderWidth = isSelected ? 0 : 2
        layer.borderColor = UIColor(
            red: 225 / 255,
            green: 218 / 255,
            blue: 238 / 255,
            alpha: 1
        ).cgColor
        setTitleColor(
            isSelected
                ? .black
                : UIColor(red: 225 / 255, green: 218 / 255, blue: 238 / 255, alpha: 1),
            for: .normal
        )
    }
}
