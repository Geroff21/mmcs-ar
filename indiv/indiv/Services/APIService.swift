import Foundation

// Модель для хранения информации о модели
struct PolyPizzaResponse: Codable {
    let total: Int
    let results: [Model]
}

// Модель для одной модели (например, "Police Car")
struct Model: Codable {
    let ID: String
    let Title: String
    let Creator: CreatorModel
    let Thumbnail: String
    let Download: String
}

// Модель для хранения информации о модели
struct CreatorModel: Codable {
    let Username: String
}

class APIService {
    
    static let shared = APIService()
    
    // Ваш ключ API
    private let apiKey = "06d6b2b6cdaf419ba7e5abd1c95179d7"  // Замените на ваш реальный ключ

    // Функция для запроса модели по ключевому слову
        func fetchModel(keyword: String, completion: @escaping (Result<[Model], Error>) -> Void) {
            // Формируем URL запроса
            guard let url = URL(string: "https://api.poly.pizza/v1.1/search/\(keyword)") else {
                completion(.failure(APIError.invalidURL))
                return
            }
            
            print("API запрос", url)
            // Создаем запрос с нужным заголовком
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "x-auth-token")
            
            // Создаем задачу для запроса
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Проверяем, что пришли данные
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                // Декодируем JSON в модель
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PolyPizzaResponse.self, from: data)
                    
                    completion(.success(response.results))
                } catch {
                    completion(.failure(error))
                }
            }
            
            // Запускаем задачу
            task.resume()
        }
        
        enum APIError: Error {
            case invalidURL
            case noData
        }
    }
