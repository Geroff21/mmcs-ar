import UIKit
import UniformTypeIdentifiers
import Foundation

protocol DocumentPickerDelegate: AnyObject {
    func didPickDocument(url: URL)
    func didCancelDocumentSelection()
}

class DocumentHelper: NSObject, UIDocumentPickerDelegate {
    var delegate: DocumentPickerDelegate?

    func presentPicker(on viewController: UIViewController) {
        guard let glbType = UTType(filenameExtension: "glb") else {return}
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [glbType], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            // Чтение данных из выбранного файла
            
            do {
                let fileData = try Data(contentsOf: url)
                
                delegate?.didPickDocument(url: url)
                // Используем вашу функцию saveFile для сохранения данных в Documents
                saveFile(fileName: url.lastPathComponent, data: fileData)
            } catch {
                print("Ошибка при чтении файла: \(error.localizedDescription)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.didCancelDocumentSelection()
    }
    
    // MARK: - Helper Method to Truncate File Name
    func truncateFileName(_ fileName: String) -> String {
        let maxLength = 20
        if fileName.count > maxLength {
            let truncatedName = fileName.prefix(maxLength) + "..."
            return String(truncatedName)
        }
        return fileName
    }
    
    // Функция для скачивания файла .glb
    func downloadGLBFile(fileName: String, from url: URL, completion: @escaping (URL?) -> Void) {
        // Создаем запрос для скачивания файла
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location else {
                print("Ошибка при скачивании файла: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
        
            do {
                let fileData = try Data(contentsOf: location)
                
                // Удаляем файл, если он уже существует
                self.deleteFile(fileName: fileName)
                
                // Сохраняем файл в Documents
                if let savedURL = self.saveFile(fileName: fileName, data: fileData) {
                    print("Файл успешно скачан и сохранен в \(savedURL.path)")
                    completion(savedURL) // Возвращаем путь к файлу
                } else {
                    print("Не удалось сохранить файл.")
                    completion(nil)
                }
            } catch {
                print("Ошибка при чтении временного файла: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume() // Запускаем задачу на скачивание
    }
    
    func downloadGLBFileToTemp(from url: URL, completion: @escaping (URL?) -> Void) {
        // Создаем задачу для скачивания файла
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location, error == nil else {
                print("Ошибка при скачивании файла: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                // Путь к временной директории
                let tempDirectory = NSTemporaryDirectory()
                let fileName = response?.suggestedFilename ?? "tempFile.glb"
                let tempURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)
                
                // Удаляем файл, если он уже существует
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: tempURL.path) {
                    try fileManager.removeItem(at: tempURL)
                }

                // Перемещаем файл в временную директорию
                try fileManager.moveItem(at: location, to: tempURL)
                print("Файл успешно скачан во временную директорию: \(tempURL.path)")
                completion(tempURL) // Возвращаем путь к временной директории
            } catch {
                print("Ошибка при перемещении файла: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume() // Запускаем задачу скачивания
    }

    
    // MARK: - Delete File from Documents Directory
    func deleteFile(fileName: String) {
        let fileManager = FileManager.default
        do {
            // Получаем путь к каталогу документов
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Не удалось найти каталог Documents.")
                return
            }
            
            // Генерируем путь к файлу
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Проверяем, существует ли файл
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                print("Файл успешно удален: \(fileURL.path)")
            }
        } catch let error as NSError {
            print("Ошибка при удалении файла: \(error.localizedDescription), код ошибки: \(error.code)")
        }
    }
    
    func saveFile(fileName: String, data: Data) -> URL? {
        let fileManager = FileManager.default
        do {
            // Получаем путь к каталогу документов
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Не удалось найти каталог Documents.")
                return nil
            }
            
            // Генерируем путь к файлу
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Проверяем, существует ли файл
            if fileManager.fileExists(atPath: fileURL.path) {
                // Если файл существует, удаляем его
                try fileManager.removeItem(at: fileURL)
                print("Файл с таким именем уже существует, удален и заменен.")
            }
            
            // Сохраняем данные в файл
            try data.write(to: fileURL)
            print("Файл успешно сохранен в \(fileURL.path)")
            return fileURL
        } catch let error as NSError {
            print("Ошибка при сохранении файла: \(error.localizedDescription), код ошибки: \(error.code)")
            return nil
        }
    }


}
