import UIKit

class KivroViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KivroPalette.background
        configureDismissKeyboardGesture()
    }

    private func configureDismissKeyboardGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
