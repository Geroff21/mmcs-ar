import UIKit

class AlertHelper {
    
    // MARK: - Helper Method for Alerts
    func showAlertMessage(on viewController: UIViewController, message: String) {
        let alertController = UIAlertController(title: "Результат", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func showAlert(on viewController: UIViewController, title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func showTextInputAlert(on viewController: UIViewController, title: String, message: String?, placeholder: String, completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = placeholder
        }
        let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion(alertController.textFields?.first?.text)
        }
        alertController.addAction(confirmAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }
}
