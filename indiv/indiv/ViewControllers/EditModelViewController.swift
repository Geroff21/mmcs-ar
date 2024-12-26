import UIKit
import CoreData
import UniformTypeIdentifiers

class EditModelViewController: UIViewController, DocumentPickerDelegate, ImagePickerDelegate {
    
    @IBOutlet var nameTF: UITextField!
    @IBOutlet var descTF: UITextField!
    @IBOutlet var selectFileButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var bgImageView: UIImageView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var setPhotobgButton: UIButton!
    @IBOutlet var selectFileApiButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    
    var mainViewController: MainViewController?
    
    let documentHelper = DocumentHelper()
    let imageHelper = ImageHelper()
    let alertHelper = AlertHelper()
    
    var selectedFilePath: String?
    var selectedFileName: String?
    var fromApi: Bool = false
    var selectedPhotobgName: String?
    var model: Item? // Полученная модель для редактирования
    
    var apiQuery = ""
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        documentHelper.delegate = self
        imageHelper.delegate = self
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Вызов функции для настройки текстовых полей
        configureTextField(nameTF, placeholder: "Name")
        configureTextField(descTF, placeholder: "Author")
        
        bgImageView.layer.cornerRadius = 5
        bgImageView.layer.masksToBounds = true
        
        title = "Редактировать модель"
        view.backgroundColor = .white
        
        // Заполняем текстовые поля текущими данными модели
        if let model = model {
            nameTF.text = model.name
            descTF.text = model.desc
            if let filePath = model.file {
                selectedFileName = filePath
                guard let fileName = selectedFileName else { return }
                statusLabel.text = "Model: " + documentHelper.truncateFileName(fileName) // Устанавливаем имя файла на кнопке
            }
            if let photobgPath = model.photobg {
                selectedPhotobgName = photobgPath
                
                if let loadedImage = imageHelper.loadImageFromDocuments(fileName: selectedPhotobgName ?? "") {
                    bgImageView.image = loadedImage
                    setPhotobgButton.setTitle("Change thumbnail", for: .normal)
                } else {
                    print("Ошибка: не удалось загрузить изображение.")
                }
            }
            
        }
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
    
    // MARK: - Save Model to Core Data
    @IBAction func saveModel() {
        guard let name = nameTF.text, !name.isEmpty,
              let description = descTF.text, !description.isEmpty else {
            alertHelper.showAlertMessage(on: self, message: "Пожалуйста, введите название и описание модели.")
            return
        }
        
        if let model = model {
            
            // Создаем DispatchGroup для синхронизации асинхронных операций
            let dispatchGroup = DispatchGroup()
            
            print(self.selectedFileName, model.file)
            
            if let nFileName = self.selectedFileName {
                if (nFileName != model.file) {
                    self.documentHelper.deleteFile(fileName: model.file ?? "")
                }
            }
            
            if let nPhotoName = self.selectedPhotobgName {
                if (nPhotoName != model.photobg) {
                    self.documentHelper.deleteFile(fileName: model.photobg ?? "")
                }
            }

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
                    PersistenceService.updateItem(item: model, newName: name, newDescription: description, newFilePath: self.selectedFileName, newPhotobg: self.selectedPhotobgName)
                    self.mainViewController?.fetchModels()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
            else {
                PersistenceService.updateItem(item: model, newName: name, newDescription: description, newFilePath: self.selectedFileName, newPhotobg: self.selectedPhotobgName)
                self.mainViewController?.fetchModels()
                self.navigationController?.popToRootViewController(animated: true)
            }
            
        } else {
            alertHelper.showAlertMessage(on: self, message: "Не удалось найти модель для редактирования.")
        }
    }
    
    @IBAction func deleteModel() {
        
        if let model = model {
            
            if let fileName = model.file { documentHelper.deleteFile(fileName: fileName) }
            if let photoName = model.photobg { documentHelper.deleteFile(fileName: photoName) }
            
            PersistenceService.deleteItem(item: model)
            mainViewController?.fetchModels()
            self.navigationController?.popToRootViewController(animated: true)
            
        } else {
            alertHelper.showAlertMessage(on: self, message: "Не удалось найти модель для удаления.")
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
    
    func didPickDocument(url: URL) {
        selectedFilePath = url.path
        selectedFileName = url.lastPathComponent
        statusLabel.text = "Model: " + documentHelper.truncateFileName(selectedFileName ?? "")
    }
    
    func didPickImage(image: UIImage, url: URL?) {
        selectedPhotobgName = url?.lastPathComponent
        bgImageView.image = image
        setPhotobgButton.setTitle("Change thumbnail", for: .normal)
    }
    
    func didCancelDocumentSelection() {print("cancel doc selection")}
    func didCancelImageSelection() {print("cancel image selection")}
    
}
