import UIKit
import SnapKit

final class KivroImagePreviewViewController: UIViewController, UIScrollViewDelegate {
    private let previewImage: UIImage
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    init(image: UIImage) {
        previewImage = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    private func configureView() {
        view.backgroundColor = .black

        let header = KivroPageHeaderView(title: "")
        header.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(KivroPageHeaderLayout.height)
        }

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        imageView.image = previewImage
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.frameLayoutGuide)
        }

    }
}
