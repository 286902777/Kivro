import UIKit
import WebKit
import SnapKit

enum KivroLegalDocument: Int, CaseIterable {
    case terms
    case privacy

    var titleKey: String {
        switch self {
        case .terms: return "legal.terms"
        case .privacy: return "legal.privacy"
        }
    }

    var url: URL {
        switch self {
        case .terms:
            return URL(string: KivroConstantMask.join(
                "https://", "app.8or1dovt.link/", "users"
            ))!
        case .privacy:
            return URL(string: KivroConstantMask.join(
                "https://", "app.8or1dovt.link/", "privacy"
            ))!
        }
    }
}

final class LegalDocumentsViewController: KivroViewController, WKNavigationDelegate {
    private let document: KivroLegalDocument
    private let loadingOverlay = KivroLoadingOverlay()
    private let navigationHeader = UIView()
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

    init(initialDocument: KivroLegalDocument) {
        self.document = initialDocument
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(red: 15 / 255, green: 10 / 255, blue: 22 / 255, alpha: 1)
        configureLayout()
        load(document)
    }

    private func configureLayout() {
        configureNavigationHeader()
        configureWebView()
    }

    private func configureNavigationHeader() {
        navigationHeader.backgroundColor = view.backgroundColor
        view.addSubview(navigationHeader)
        navigationHeader.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(54)
        }

        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "kivro_navigation_back"), for: .normal)
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        navigationHeader.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(5)
            make.size.equalTo(44)
        }

        let titleLabel = UILabel()
        titleLabel.text = KivroStrings.value(document.titleKey)
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 22, weight: .bold)
        titleLabel.textAlignment = .center
        navigationHeader.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
    }

    private func configureWebView() {
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(navigationHeader.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func load(_ document: KivroLegalDocument) {
        loadingOverlay.show(in: view)
        webView.load(URLRequest(url: document.url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingOverlay.hide()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        showLoadFailure()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showLoadFailure()
    }

    private func showLoadFailure() {
        loadingOverlay.hide()
        KivroToastPresenter.show(message: KivroStrings.value("legal.load_failed"), in: view)
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
