import UIKit

class FetchAndSaveViewController: UIViewController {
    
    var queryTextField: UITextField!
    var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настройка UI
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        // Настройка текстового поля для ввода запроса
        queryTextField = UITextField()
        queryTextField.borderStyle = .roundedRect
        queryTextField.placeholder = "Enter query"
        queryTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(queryTextField)
        
        // Настройка кнопки для выполнения запроса
        saveButton = UIButton(type: .system)
        saveButton.setTitle("Search and Save", for: .normal)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(searchAndSave), for: .touchUpInside)
        view.addSubview(saveButton)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            queryTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            queryTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            queryTextField.widthAnchor.constraint(equalToConstant: 300),
            
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.topAnchor.constraint(equalTo: queryTextField.bottomAnchor, constant: 20)
        ])
    }
    
    @objc func searchAndSave() {
        guard let query = queryTextField.text, !query.isEmpty else {
            print("Please enter a query.")
            return
        }
        
        // Вызов API для поиска модели
        APIService.shared.fetchModel(query: query) { model in
            if let model = model {
                // Сохранение модели в Core Data
                CoreDataManager.shared.saveModel(name: model.name, downloadURL: model.downloadURL)
                print("Model saved: \(model.name)")
            } else {
                print("No model found for query: \(query)")
            }
        }
    }
}
