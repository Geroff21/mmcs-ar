import UIKit
import CoreData

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var models: [Item] = []
    let imageHelper = ImageHelper()
    var thumbnailsState = true

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        title = "Список моделей"
        view.backgroundColor = .white
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        setupNavigationBar()
        mainButtons.setupAddButton(on: view) {self.openCreateView()}
        mainButtons.setupARButton(on: view) {self.openARView()}
        
        // Настроим таблицу
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        // Загружаем данные из базы данных
        fetchModels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let isThumbnailsEnabled = UserDefaults.standard.bool(forKey: "thumbnailsState")
        
        if (thumbnailsState != isThumbnailsEnabled) {
            tableView.reloadData()
            thumbnailsState = isThumbnailsEnabled
        }
    }
    
    func setupNavigationBar() {
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        
        navigationItem.rightBarButtonItems = [settingsButton]
    }
    
    @objc func openSettings() {
        let storyboard = UIStoryboard(name: "SettingsView", bundle: nil)
        if let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController {
            navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    @objc func openCreateView() {
        let storyboard = UIStoryboard(name: "CreateView", bundle: nil)
        if let createVC = storyboard.instantiateViewController(withIdentifier: "CreateModelViewController") as? CreateModelViewController {
            createVC.mainViewController = self
            navigationController?.pushViewController(createVC, animated: true)
        }
    }
    
    @objc func openEditView(model: Item) {
        let storyboard = UIStoryboard(name: "EditView", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditModelViewController") as? EditModelViewController {
            editVC.mainViewController = self
            editVC.model = model
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    @objc func openARView() {
        let storyboard = UIStoryboard(name: "ARView", bundle: nil)
        if let arVC = storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ARViewController {
            navigationController?.pushViewController(arVC, animated: true)
        }
    }
    
    // Получение данных из Core Data
    func fetchModels() {
        if let fetchedModels = PersistenceService.fetchItems() {
            models = fetchedModels
            tableView.reloadData()
        } else {
            print("Ошибка при извлечении данных.")
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ModelCell", for: indexPath) as? CustomModelCell else {
            return UITableViewCell()
        }

        let model = models[indexPath.row]
        
        cell.nameLabel.text = model.name ?? "Name"
        cell.descLabel.text = "By " + (model.desc ?? "Author")
        
        if (thumbnailsState) {
            let targetSize = CGSize(width: 100, height: 100)
            cell.bgImageCellView.image = imageHelper.loadThumbnailFromDocuments(fileName: model.photobg ?? "", targetSize: targetSize)
        } else {
            cell.bgImageCellView.image = nil
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // При выборе модели, переходим на экран редактирования
        let selectedModel = models[indexPath.row]
        openEditView(model: selectedModel)
    }

}
