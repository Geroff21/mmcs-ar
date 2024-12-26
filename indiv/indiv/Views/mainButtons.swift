import UIKit

class mainButtons: UIViewController {
    
    // Метод для настройки AddButton с замыканием
    static func setupAddButton(on view: UIView, openCreateViewAction: @escaping () -> Void) {
        let floatingButton = UIButton(type: .system)
        let plusImage = UIImage(systemName: "plus.circle.fill")
        floatingButton.setImage(plusImage, for: .normal)
        floatingButton.tintColor = .white
        floatingButton.backgroundColor = .black
        floatingButton.layer.cornerRadius = 30
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOpacity = 0.3
        floatingButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        floatingButton.layer.shadowRadius = 4

        view.addSubview(floatingButton)
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            floatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        view.bringSubviewToFront(floatingButton)

        // Использование замыкания для обработки нажатия
        floatingButton.addAction(UIAction(handler: { _ in
            openCreateViewAction()
        }), for: .touchUpInside)
    }

    // Метод для настройки ARButton с замыканием
    static func setupARButton(on view: UIView, openARViewAction: @escaping () -> Void) {
        let floatingButton = UIButton(type: .system)
        let plusImage = UIImage(systemName: "paperplane.fill")
        floatingButton.setImage(plusImage, for: .normal)
        floatingButton.tintColor = .white
        floatingButton.backgroundColor = .black
        floatingButton.layer.cornerRadius = 30
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOpacity = 0.3
        floatingButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        floatingButton.layer.shadowRadius = 4

        view.addSubview(floatingButton)
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            floatingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        view.bringSubviewToFront(floatingButton)

        // Использование замыкания для обработки нажатия
        floatingButton.addAction(UIAction(handler: { _ in
            openARViewAction()
        }), for: .touchUpInside)
    }
}
