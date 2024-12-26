import UIKit
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers
import Foundation

class CreateModelViewController: UIViewController, DocumentPickerDelegate, ImagePickerDelegate {

    var mainViewController: MainViewController?
    
    let documentHelper = DocumentHelper()
    let imageHelper = ImageHelper()
    let alertHelper = AlertHelper()
    
    @IBOutlet var nameTF: UITextField!
    @IBOutlet var descTF: UITextField!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var selectFileButton: UIButton!
    @IBOutlet var selectFileApiButton: UIButton!
    @IBOutlet var selectPhotobbgButton: UIButton!
    @IBOutlet var pgImageView: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    
    var selectedFilePath: String?
    var fromApi: Bool = false
    var selectedFileName: String?
    var selectedPhotobgName: String?
    
    var apiQuery: String = ""
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        documentHelper.delegate = self
        imageHelper.delegate = self
        
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        // Вызов функции для настройки текстовых полей
        configureTextField(nameTF, placeholder: "Name")
        configureTextField(descTF, placeholder: "Author")
        
        pgImageView.layer.cornerRadius = 5
        pgImageView.layer.masksToBounds = true

        title = "Добавить модель"
        view.backgroundColor = .white
    }
    
    // MARK: - Save Model to Core Data
    @IBAction func saveModel() {
        guard let name = nameTF.text, !name.isEmpty,
              let description = descTF.text, !description.isEmpty else {
            self.alertHelper.showAlertMessage(on: self, message: "Пожалуйста, введите название и описание модели.")
            return
        }
        
        print("КАЧАЮ", self.fromApi)
        
        // Создаем DispatchGroup для синхронизации асинхронных операций
        let dispatchGroup = DispatchGroup()

        if (self.fromApi) {
            
            self.activityIndicator.startAnimating()
            
            if let glbURL = URL(string: self.selectedFilePath ?? "") {
                dispatchGroup.enter() // Входим в группу
                
                let customName = self.selectedFileName
                if (self.selectedFileName != customName) {
                    self.documentHelper.deleteFile(fileName: customName ?? "")
                }
                
                self.documentHelper.downloadGLBFile(fileName: customName ?? "", from: glbURL) { fileURL in
                    if let fileURL = fileURL {
                        DispatchQueue.main.async {
                            self.didPickDocument(url: fileURL)
                        }
                    } else {
                        // Обработка ошибки
                        print("Не удалось скачать или сохранить файл .glb.")
                    }
                    dispatchGroup.leave() // Выходим из группы
                }
            }
            
            if let imageURL = URL(string: self.selectedPhotobgName ?? "") {
                dispatchGroup.enter() // Входим в группу
                
                self.imageHelper.downloadImage(from: imageURL) { image, fileURL in
                    if let image = image, let fileURL = fileURL {
                        DispatchQueue.main.async {
                            self.didPickImage(image: image, url: fileURL)
                        }
                    } else {
                        // Обработка ошибки
                        print("Не удалось скачать или сохранить изображение.")
                    }
                    dispatchGroup.leave() // Выходим из группы
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.activityIndicator.stopAnimating()
                PersistenceService.addItem(name: name, description: description, filePath: self.selectedFileName, photobg: self.selectedPhotobgName)
                self.mainViewController?.fetchModels()
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        else {
            PersistenceService.addItem(name: name, description: description, filePath: selectedFileName, photobg: selectedPhotobgName)
            self.mainViewController?.fetchModels()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: - Select SCN File
    @IBAction func selectFile() {
        documentHelper.presentPicker(on: self)
    }
    
    // MARK: - Открыть Галерею
    @IBAction func openGallery() {
        imageHelper.presentGallery(on: self)
    }
    
    // MARK: - Select Model via API
    @IBAction func selectFileApi() {
   
        let alertController = UIAlertController(title: "Введите запрос для модели", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Введите название модели"
        }
        
        let searchAction = UIAlertAction(title: "Поиск", style: .default) { _ in
            if let query = alertController.textFields?.first?.text, !query.isEmpty {
                self.apiQuery = query
                self.openApiScreenView()
                
            } else {
                self.alertHelper.showAlertMessage(on: self, message: "Пожалуйста, введите запрос для поиска модели.")
            }
        }
        
        alertController.addAction(searchAction)
        alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func openApiScreenView() {
        
        let storyboard = UIStoryboard(name: "ApiScreenView", bundle: nil)
        if let apiScreenVC = storyboard.instantiateViewController(withIdentifier: "ApiScreenViewController") as? ApiScreenViewController {
            apiScreenVC.query = self.apiQuery
            self.navigationController?.pushViewController(apiScreenVC, animated: true)
        }
        
    }
    
    func didPickDocument(url: URL) {
        selectedFilePath = url.path
        selectedFileName = url.lastPathComponent
        statusLabel.text = "Model: " + documentHelper.truncateFileName(selectedFileName ?? "")
    }
    
    func didPickImage(image: UIImage, url: URL?) {
        selectedPhotobgName = url?.lastPathComponent
        pgImageView.image = image
        selectPhotobbgButton.setTitle("Change thumbnail", for: .normal)
    }
    
    func didCancelDocumentSelection() {print("cancel doc selection")}
    func didCancelImageSelection() {print("cancel image selection")}
    
}
