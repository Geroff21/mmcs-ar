import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet var textRecognitionLabel: UILabel!
    @IBOutlet var ThumbnailsLabel: UILabel!
    @IBOutlet var directUploadLabel: UILabel!
    
    @IBOutlet var textRecognitionSwitch: UISwitch!
    @IBOutlet var thumbnailsSwitch: UISwitch!
    @IBOutlet var directUploadSwitch: UISwitch!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        view.backgroundColor = .white
        
        // Инициализация состояний переключателей
        initializeSwitchStates()
        
    }
    
    // MARK: - Инициализация состояний переключателей
    func initializeSwitchStates() {
        if let textRecognitionSwitch = textRecognitionSwitch {
            textRecognitionSwitch.isOn = UserDefaults.standard.bool(forKey: "textRecognitionState")
        }
        if let thumbnailsSwitch = thumbnailsSwitch {
            thumbnailsSwitch.isOn = UserDefaults.standard.bool(forKey: "thumbnailsState")
        }
        if let directUploadSwitch = directUploadSwitch {
            directUploadSwitch.isOn = UserDefaults.standard.bool(forKey: "directUploadState")
        }
    }

    @IBAction func textRecognitionChanged(_ sender: UISwitch) {
        let isOn = sender.isOn
        UserDefaults.standard.set(isOn, forKey: "textRecognitionState")
        print("Распознавание текста: \(isOn ? "включено" : "выключено")")
    }

    @IBAction func directUploadChanged(_ sender: UISwitch) {
        let isOn = sender.isOn
        UserDefaults.standard.set(isOn, forKey: "directUploadState")
        print("Прямое добавление объектов в БД: \(isOn ? "включено" : "выключено")")
    }

    @IBAction func thumbnailsChanged(_ sender: UISwitch) {
        let isOn = sender.isOn
        UserDefaults.standard.set(isOn, forKey: "thumbnailsState")
        print("Показ миниатюр: \(isOn ? "включен" : "выключен")")
    }
    
}
