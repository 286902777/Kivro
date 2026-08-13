import AVKit
import UIKit
import SnapKit

final class KivroVideoPlayerViewController: KivroViewController {
    private let videoURL: URL
    private let playerController = AVPlayerViewController()

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .black

        let header = KivroPageHeaderView(title: "")
        header.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        addChild(playerController)
        playerController.player = AVPlayer(url: videoURL)
        playerController.showsPlaybackControls = true
        view.addSubview(playerController.view)
        playerController.view.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        playerController.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerController.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerController.player?.pause()
    }
}
