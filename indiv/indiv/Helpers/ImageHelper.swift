import UIKit
import Foundation

protocol ImagePickerDelegate: AnyObject {
    func didPickImage(image: UIImage, url: URL?)
    func didCancelImageSelection()
}

class ImageHelper: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: ImagePickerDelegate?

    // Создание кэша для изображений
    private let imageCache = NSCache<NSString, UIImage>()

    func presentGallery(on viewController: UIViewController) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        viewController.present(imagePicker, animated: true, completion: nil)
    }
    
    // Функция для сохранения изображения в каталог документов
    func saveImageToDocuments(image: UIImage, fileName: String) -> URL? {
        // Получаем путь к каталогу документов
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Преобразуем изображение в данные и сохраняем в файл
        if let data = image.jpegData(compressionQuality: 1.0) {
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                print("Ошибка при сохранении изображения: \(error)")
                return nil
            }
        }
        return nil
    }
    
    // Функция для загрузки изображения из каталога документов
    func loadImageFromDocuments(fileName: String) -> UIImage? {
        // Сначала проверяем, есть ли изображение в кэше
        if let cachedImage = getImageFromCache(for: fileName) {
            // Если изображение найдено в кэше, возвращаем его
            print("загружено из кэша")
            return cachedImage
        }
        
        // Если изображения нет в кэше, загружаем его из каталога документов
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Загружаем изображение
        if let image = UIImage(contentsOfFile: fileURL.path) {
            // Кэшируем изображение, если оно успешно загружено
            cacheImage(image, for: fileName)
            print("загружено в кэш")
            return image
        }
        
        // Если изображение не удалось загрузить, возвращаем nil
        return nil
    }
    
    private func createThumbnail(from image: UIImage, targetSize: CGSize) -> UIImage? {
        // Пропорционально изменяем размер изображения, чтобы оно поместилось в targetSize
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if aspectRatio > 1 { // Широкие изображения
            newSize = CGSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else { // Высокие изображения
            newSize = CGSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
        
        // Создаем графический контекст для изменения размера изображения
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail
    }

    // Функция для загрузки изображения из каталога документов с кэшированием миниатюр
    func loadThumbnailFromDocuments(fileName: String, targetSize: CGSize) -> UIImage? {
        // Сначала проверяем, есть ли миниатюра в кэше
        if let cachedThumbnail = getImageFromCache(for: fileName) {
            print("загружено из кэша (мииниатюра)")
            return cachedThumbnail
        }
        
        // Если миниатюры нет в кэше, загружаем изображение из каталога документов
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Загружаем изображение
        if let image = UIImage(contentsOfFile: fileURL.path) {
            // Генерируем миниатюру
            if let thumbnail = createThumbnail(from: image, targetSize: targetSize) {
                // Кэшируем миниатюру, если она успешно создана
                cacheImage(thumbnail, for: fileName)
                print("загружено в кэш (мииниатюра)")
                return thumbnail
            }
        }
        
        // Если изображение не удалось загрузить или миниатюру не удалось создать, возвращаем nil
        return nil
    }

    
    // Функция для получения изображения из кэша
    private func getImageFromCache(for key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    // Функция для кэширования изображения
    private func cacheImage(_ image: UIImage, for key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }

    // Обрабатываем выбор изображения
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage, let url = info[.imageURL] as? URL {
            // Сначала пытаемся загрузить изображение из кэша
            if let cachedImage = getImageFromCache(for: url.lastPathComponent) {
                // Если изображение есть в кэше, передаем его
                delegate?.didPickImage(image: cachedImage, url: url)
            } else {
                // Если изображения нет в кэше, сохраняем его в документы и кэшируем
                if let savedURL = saveImageToDocuments(image: image, fileName: url.lastPathComponent) {
                    cacheImage(image, for: url.lastPathComponent)
                    delegate?.didPickImage(image: image, url: savedURL)
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // Обрабатываем отмену выбора изображения
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.didCancelImageSelection()
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Функция для скачивания изображения по URL
    func downloadImage(from url: URL, completion: @escaping (UIImage?, URL?) -> Void) {
        // Создаем запрос для скачивания данных
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                // Скачивание прошло успешно, теперь сохраняем в документы
                let fileManager = FileManager.default
                guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    completion(nil, nil)
                    return
                }
                
                // Генерируем уникальное имя для файла
                let fileName = url.lastPathComponent
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Сохраняем изображение в файл
                do {
                    try data.write(to: fileURL)
                    print("Изображение сохранено в \(fileURL.path)")
                    completion(image, fileURL)  // Возвращаем изображение и путь
                } catch {
                    print("Ошибка при сохранении изображения: \(error)")
                    completion(nil, nil)
                }
            } else {
                print("Ошибка при скачивании изображения: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
            }
        }
        
        task.resume()  // Запускаем задачу на скачивание
    }
    
    func downloadImageWithoutSaving(from url: URL, completion: @escaping (UIImage?, URL?) -> Void) {
        // Создаем запрос для скачивания данных
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image, url)
            } else {
                print("Ошибка при скачивании изображения: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
            }
        }
        
        task.resume()  // Запускаем задачу на скачивание
    }

}
