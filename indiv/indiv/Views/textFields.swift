import UIKit

func configureTextField(_ textField: UITextField, placeholder: String) {
    textField.layer.borderWidth = 1.0
    textField.layer.borderColor = UIColor.tintColor.cgColor
    textField.layer.cornerRadius = 5.0
    textField.layer.masksToBounds = true
    
    let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.gray // Цвет placeholder
    ]
    textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
}
