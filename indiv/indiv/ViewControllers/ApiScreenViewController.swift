import UIKit
import CoreData

struct ApiItem {
    let name: String
    let desc: String
    let file: String
    let photobg: String
    let image: UIImage
    let fileName: String
}

class ApiScreenViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ImagePickerDelegate, DocumentPickerDelegate {
    
    var apiModels: [ApiItem] = [] // Массив моделей
    var thumbnailsState = true
    
    let documentHelper = DocumentHelper()
    let imageHelper = ImageHelper()
    let alertHelper = AlertHelper()
    
    @IBOutlet var tableView: UITableView!
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    var query: String?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        title = "Polly Pizza API"
        view.backgroundColor = .white
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        activityIndicator.center = view.center // Центрируем индикатор на экране
        activityIndicator.hidesWhenStopped = true // Скрываем индикатор, когда он остановлен
        view.addSubview(activityIndicator)
        
        imageHelper.delegate = self
        
        // Настроим таблицу
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        // Загружаем данные из базы данных
        fetchModelsFromAPI(query: query ?? "")
    }
    
    func fetchModelsFromAPI(query: String) {
        self.activityIndicator.startAnimating()
        
        APIService.shared.fetchModel(keyword: query) { result in
            switch result {
            case .success(let models):
                self.handleFetchedModels(models, query: query)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }

    func handleFetchedModels(_ models: [Model], query: String) {
        // Проверяем, что модели есть в ответе
        if models.isEmpty {
            DispatchQueue.main.async {
                self.alertHelper.showAlertMessage(on: self, message: "Модели не найдены по запросу \(query).")
            }
        } else {
            // Процесс обработки моделей
            for model in models {
                fetchImageForModel(model)
            }
        }
    }
    
    func fetchImageForModel(_ model: Model) {
        if let imageURL = URL(string: model.Thumbnail) {
            self.imageHelper.downloadImageWithoutSaving(from: imageURL) { image, fileURL in
                self.handleImageDownload(image: image, fileURL: fileURL, model: model)
            }
        }
    }
    
    func handleImageDownload(image: UIImage?, fileURL: URL?, model: Model) {
        if let image = image, let fileURL = fileURL {
            DispatchQueue.main.async {
                self.addModelToTable(model: model, image: image, fileURL: fileURL)
            }
        } else {
            // Обработка ошибки при скачивании изображения
            print("Не удалось скачать или сохранить изображение для модели: \(model.Title)")
        }
    }
    
    func addModelToTable(model: Model, image: UIImage, fileURL: URL) {
        let fileName = model.Title + "_" + model.ID.prefix(4) + ".glb"
        let newItem = ApiItem(name: model.Title, desc: model.Creator.Username, file: model.Download, photobg: model.Thumbnail, image: image, fileName: fileName)
        
        self.apiModels.append(newItem)
        self.tableView.reloadData()
        self.activityIndicator.stopAnimating()
    }
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.alertHelper.showAlertMessage(on: self, message: "Ошибка: \(error.localizedDescription)")
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apiModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApiModelCell", for: indexPath) as? CustomApiModelCell else {
            return UITableViewCell()
        }

        let model = apiModels[indexPath.row]
        
        cell.nameLabel.text = model.name
        cell.descLabel.text = "By " + model.desc
        cell.bgImageSellView.image = model.image

        return cell
    }
    
    func didPickImage(image: UIImage, url: URL?) {}
    func didCancelImageSelection() {}
    
    func didPickDocument(url: URL) {}
    func didCancelDocumentSelection() {}

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedModel = apiModels[indexPath.row]
        
        // Получаем текущий стек контроллеров
        if let viewControllers = self.navigationController?.viewControllers {
            for vc in viewControllers {
                if let editModelVC = vc as? EditModelViewController {
                    // Если мы пришли с EditModelViewController
                    editModelVC.nameTF.text = selectedModel.name
                    editModelVC.descTF.text = selectedModel.desc
                    editModelVC.selectedFileName = selectedModel.fileName
                    editModelVC.selectedFilePath = selectedModel.file
                    editModelVC.selectedPhotobgName = selectedModel.photobg
                    editModelVC.bgImageView.image = selectedModel.image
                    
                    editModelVC.fromApi = true
                    editModelVC.setPhotobgButton.setTitle("Change thumbnail", for: .normal)
                    editModelVC.statusLabel.text = "Model: " + documentHelper.truncateFileName(selectedModel.fileName)
                    
                    self.navigationController?.popViewController(animated: true)
                    break
                } else if let createModelVC = vc as? CreateModelViewController {
                    // Если мы пришли с CreateModelViewController
                    createModelVC.nameTF.text = selectedModel.name
                    createModelVC.descTF.text = selectedModel.desc
                    createModelVC.selectedFileName = selectedModel.fileName
                    createModelVC.selectedFilePath = selectedModel.file
                    createModelVC.selectedPhotobgName = selectedModel.photobg
                    createModelVC.pgImageView.image = selectedModel.image
                    
                    createModelVC.fromApi = true
                    createModelVC.selectPhotobbgButton.setTitle("Change thumbnail", for: .normal)
                    createModelVC.statusLabel.text = "Model: " + documentHelper.truncateFileName(selectedModel.fileName)
                    
                    self.navigationController?.popViewController(animated: true)
                    break
                }
                else if let arVC = vc as? ARViewController {
                    // Если мы пришли с CreateModelViewController
                    arVC.nameFromApi = selectedModel.name
                    arVC.selectedFileName = selectedModel.fileName
                    arVC.selectedFilePath = selectedModel.file
                      
                    self.navigationController?.popViewController(animated: true)
                    break
                }
            }
        }
        
    }

}
