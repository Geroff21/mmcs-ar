import UIKit
import ARKit
import Vision
import SceneKit
import GLTFSceneKit



class ARViewController: UIViewController, ARSCNViewDelegate, DocumentPickerDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var detectButton: UIButton!
    @IBOutlet var resultLabel: UILabel!
    
    var textRecognitionState = false
    var directUploadState = false
    
    var nameFromApi: String?
    var selectedFileName: String?
    var selectedFilePath: String?
    
    let documentHelper = DocumentHelper()
    
    var detectedPlaneAnchor: ARPlaneAnchor?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Проверяем, что sceneView не nil
        guard sceneView != nil else {
            print("Ошибка: sceneView не инициализирована.")
            return
        }
    
        // Настройка AR-сцены
        sceneView.delegate = self
        documentHelper.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration)
        
        setupGestures()
        
        detectButton.addTarget(self, action: #selector(detectTextOnPlane), for: .touchUpInside)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)

        let isTextRecognitionEnabled = UserDefaults.standard.bool(forKey: "textRecognitionState")
        let isDirectUploadEnabled = UserDefaults.standard.bool(forKey: "directUploadState")
        
        if (textRecognitionState != isTextRecognitionEnabled) {
            textRecognitionState = isTextRecognitionEnabled
        }
        
        if (directUploadState != isDirectUploadEnabled) {
            directUploadState = isDirectUploadEnabled
        }
        
        // Настройка кнопки
        if (!textRecognitionState) {
            detectButton.setTitle("Добавить модель", for: .normal)
        }else {
            detectButton.setTitle("Распознать текст", for: .normal)
        }
        
        if let filePath = selectedFilePath, let fileURL = URL(string: filePath) {
            documentHelper.downloadGLBFileToTemp(from: fileURL) { [weak self] tempURL in
                guard let self = self else { return }
                if let tempURL = tempURL {
                    print("Файл сохранен во временной папке: \(tempURL.path)")
                    self.placeModelAtPlane(from: tempURL)
                } else {
                    print("Не удалось скачать файл.")
                }
            }
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    // Метод для обработки нажатия кнопки
    @objc func detectTextOnPlane() {
        if !textRecognitionState {
            // Показываем UIAlertController для ввода текста
            let alertController = UIAlertController(title: "Введите текст", message: nil, preferredStyle: .alert)
            
            // Добавляем текстовое поле для ввода
            alertController.addTextField { textField in
                textField.placeholder = "Введите текст"
            }
            
            // Добавляем кнопку "ОК"
            let okAction = UIAlertAction(title: "ОК", style: .default) { _ in
                if let enteredText = alertController.textFields?.first?.text, !enteredText.isEmpty {
                    self.placeObjectOnPlane(objectName: enteredText)
                }
            }
            alertController.addAction(okAction)
            
            // Добавляем кнопку "Отмена"
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            // Показываем alert
            present(alertController, animated: true, completion: nil)
            
        } else {
            // Если textRecognitionState не включен, продолжаем с распознаванием текста
            // Получаем снимок текущего состояния камеры
            guard let cgImage = sceneView.snapshot().cgImage else {
                print("Не удалось получить изображение")
                return
            }

            // Создаем запрос на распознавание текста
            let request = VNRecognizeTextRequest(completionHandler: handleTextDetection)
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Ошибка при выполнении запроса распознавания текста: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func openApiScreenView(query: String) {
        
        let storyboard = UIStoryboard(name: "ApiScreenView", bundle: nil)
        if let apiScreenVC = storyboard.instantiateViewController(withIdentifier: "ApiScreenViewController") as? ApiScreenViewController {
            apiScreenVC.query = query
            self.navigationController?.pushViewController(apiScreenVC, animated: true)
        }
        
    }

    // Метод обработки результата распознавания текста
    func handleTextDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Ошибка распознавания текста: \(error.localizedDescription)")
            return
        }

        guard let results = request.results as? [VNRecognizedTextObservation] else {
            print("Нет результатов распознавания текста")
            return
        }

        // Обрабатываем каждый результат
        for result in results {
            let recognizedText = result.topCandidates(1).first?.string ?? ""
            print("Распознанный текст: \(recognizedText)")
            
            // Обновляем лейбл с распознанным текстом
            DispatchQueue.main.async {
                self.resultLabel.text = "Распознанный текст: \(recognizedText)"
                self.placeObjectOnPlane(objectName: recognizedText)
                
            }
        }
    }

    // Метод для размещения объекта на плоскости
    func placeObjectOnPlane(objectName: String) {
        guard let planeAnchor = detectedPlaneAnchor else {
            print("Плоскость не обнаружена")
            return
        }

        // Получаем 3D координаты центра плоскости
        let position = planeAnchor.transform.columns.3

        // Размещаем модель в зависимости от распознанного текста
        var objectNode: SCNNode?

        loadGLBModel(named: objectName.lowercased())

        // Перемещаем объект в центр плоскости
        if let objectNode = objectNode {
            objectNode.position = SCNVector3(position.x, position.y, position.z)
            sceneView.scene.rootNode.addChildNode(objectNode)
        }
    }

    // Метод для обнаружения плоскости
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            detectedPlaneAnchor = planeAnchor

            // Для демонстрации визуализируем плоскость с помощью полупрозрачного объекта
            let planeNode = createPlaneNode(anchor: planeAnchor)
            node.addChildNode(planeNode)
        }
    }

    // Метод для создания визуализации плоскости
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.transparentWhite
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        
        return planeNode
    }
    
    // Метод для загрузки GLB модели и размещения её на плоскости
    func loadGLBModel(named modelName: String) {
        var modelURL: URL?

        if directUploadState {
            // Переход на экран API
            openApiScreenView(query: modelName)
        } else {
            // Поиск модели в базе данных
            guard let item = PersistenceService.fetchItemByName(name: modelName),
                  let modelURLString = item.file else {
                print("Ошибка: элемент \(modelName) не найден или некорректный путь.")
                return
            }
            
            // Получаем путь к файлу модели из базы данных
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Не удалось найти каталог Documents.")
                return
            }
            
            modelURL = documentsDirectory.appendingPathComponent(modelURLString)
            if let modelURL = modelURL {
                placeModelAtPlane(from: modelURL)
            }
        }
    }

    // Метод для размещения модели на плоскости
    private func placeModelAtPlane(from url: URL) {
        loadModelFromURL(url: url) { [weak self] node in
            guard let self = self else { return }

            // Проверяем, что узел был загружен
            guard let node = node else {
                print("Ошибка: не удалось загрузить модель из URL: \(url)")
                return
            }

            // Создаем контейнер и добавляем все дочерние узлы
            let containerNode = SCNNode()
            for child in node.childNodes {
                containerNode.addChildNode(child)
        
            }
            
            let combinedNode = self.combineGeometries(of: containerNode)

            // Нормализация масштаба
            let targetScale: Float = 0.05 // Желаемый максимальный размер по одной из осей
            let currentMaxScale = max(combinedNode.boundingBox.max.x - combinedNode.boundingBox.min.x,
                                      combinedNode.boundingBox.max.y - combinedNode.boundingBox.min.y,
                                      combinedNode.boundingBox.max.z - combinedNode.boundingBox.min.z)
            let scaleFactor = targetScale / currentMaxScale // Вычисляем коэффициент нормализации

            combinedNode.scale = SCNVector3(
                scaleFactor,
                scaleFactor,
                scaleFactor
            )

            self.updatePhysicsBody(for: combinedNode)

            // Размещаем модель в центре обнаруженной плоскости
            guard let planeAnchor = self.detectedPlaneAnchor else {
                print("Ошибка: плоскость не обнаружена.")
                return
            }

            let position = planeAnchor.transform.columns.3
            combinedNode.position = SCNVector3(position.x, position.y, position.z)
            self.sceneView.scene.rootNode.addChildNode(combinedNode)
            print("Модель размещена на плоскости.")
            
            self.printAllChildNodes(of: combinedNode)
        }
    }

    // Рекурсивная функция для печати всех дочерних узлов
    func printAllChildNodes(of node: SCNNode, level: Int = 0) {
        // Отступ для вывода уровня вложенности
        let indentation = String(repeating: "  ", count: level)
        print("\(indentation)Узел: \(node.name ?? "Без имени")")
        
        // Рекурсивно обходим дочерние узлы
        for childNode in node.childNodes {
            printAllChildNodes(of: childNode, level: level + 1)
        }
    }

    // Функция для объединения всех дочерних узлов в один
    func combineAllChildNodes(of node: SCNNode) -> SCNNode {
        let combinedNode = SCNNode() // Новый узел, в который будем добавлять все дочерние узлы
        
        // Функция для рекурсивного обхода всех дочерних узлов
        func addChildNodesRecursively(from parentNode: SCNNode, to combinedNode: SCNNode) {
            // Добавляем все дочерние узлы текущего родительского узла
            for childNode in parentNode.childNodes {
                // Для каждого дочернего узла создаем копию и добавляем в объединяющий узел
                let clonedChild = childNode.clone()
                combinedNode.addChildNode(clonedChild) // Добавляем дочерний узел
                // Рекурсивно добавляем дочерние узлы каждого дочернего узла
                addChildNodesRecursively(from: childNode, to: combinedNode)
            }
        }

        // Рекурсивно добавляем все дочерние узлы родительского узла
        addChildNodesRecursively(from: node, to: combinedNode)
        
        return combinedNode
    }

    // Объединение геометрий нескольких узлов в одну
    // Функция для объединения всех геометрий дочерних узлов в одну
    func combineGeometries(of node: SCNNode) -> SCNNode {
        var combinedSources = [SCNGeometrySource]()
        var combinedElements = [SCNGeometryElement]()
        
        // Перебираем все дочерние узлы и добавляем их геометрии
        for childNode in node.childNodes {
            if let geometry = childNode.geometry {
                // Добавляем источники геометрии, если они есть
                let sources = geometry.sources
                if !sources.isEmpty {
                    combinedSources.append(contentsOf: sources)
                } else {
                    print("Предупреждение: у узла \(childNode.name ?? "Без имени") нет источников геометрии.")
                }
                
                // Добавляем элементы геометрии, если они есть
                let elements = geometry.elements
                if !elements.isEmpty {
                    combinedElements.append(contentsOf: elements)
                } else {
                    print("Предупреждение: у узла \(childNode.name ?? "Без имени") нет элементов геометрии.")
                }
            } else {
                print("Предупреждение: у узла \(childNode.name ?? "Без имени") нет геометрии.")
            }
        }
        
        // Если источников или элементов нет, то не создаем геометрию
        guard !combinedSources.isEmpty, !combinedElements.isEmpty else {
            print("Ошибка: объединенные геометрии пусты, не удалось создать новый узел.")
            return node  // Возвращаем исходный узел без изменений
        }
        
        // Создаем новую геометрию из объединенных источников и элементов
        let combinedGeometry = SCNGeometry(sources: combinedSources, elements: combinedElements)
        
        // Создаем новый узел с объединенной геометрией
        let combinedNode = SCNNode(geometry: combinedGeometry)
        
        // Возвращаем новый узел
        return combinedNode
    }





    func loadModelFromURL(url: URL, completion: @escaping (SCNNode?) -> Void) {
        do {
            print("Загрузка модели")
            // Создаем источник сцены из GLB-файла
            let sceneSource = try GLTFSceneSource(url: url)
            let scene = try sceneSource.scene()
            
            // Создаем контейнер для всех узлов
            let containerNode = SCNNode()
            
            // Рекурсивно добавляем все узлы из загруженной сцены
            func addChildNodes(from parentNode: SCNNode, to container: SCNNode) {
                for child in parentNode.childNodes {
                    container.addChildNode(child)
                }
            }
            
            // Переносим узлы из корневого узла сцены в контейнер
            addChildNodes(from: scene.rootNode, to: containerNode)
            
            // Возвращаем контейнер
            completion(containerNode)
        } catch {
            print("Ошибка при загрузке модели GLB: \(error.localizedDescription)")
            completion(nil)
        }
    }


    func didPickDocument(url: URL) {
    }
    
    func didCancelDocumentSelection() {
    }
    
    // MARK: - Настройка жестов
    func setupGestures() {

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        sceneView.addGestureRecognizer(longPressGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
    }

    // MARK: - Удаление объекта
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: nil)
            
            if let hitResult = hitResults.first, hitResult.node.parent != nil {
                hitResult.node.removeFromParentNode()
            }
        }
    }

    // MARK: - Поворот объекта
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let node = getSelectedNode(from: gesture) else { return }
        
        switch gesture.state {
        case .changed:
            node.eulerAngles.y -= Float(gesture.rotation)
            gesture.rotation = 0
        default:
            break
        }
    }

    // MARK: - Масштабирование объекта
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)

        if let hitResult = hitResults.first {
            let node = hitResult.node
            
            if let _ = node.geometry { // Проверяем, что объект имеет геометрию
                if gesture.state == .changed {
                    let scale = Float(gesture.scale) // Приведение gesture.scale к Float
                    
                    let newScale = SCNVector3(
                        node.scale.x * scale,
                        node.scale.y * scale,
                        node.scale.z * scale
                    )
                    
                    node.scale = newScale
                    updatePhysicsBody(for: node)
                    
                    gesture.scale = 1.0 // Сбрасываем значение жеста
                }
            }
        }
    }

    // MARK: - Перемещение объекта
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let node = getSelectedNode(from: gesture) else { return }
        
        let translation = gesture.translation(in: sceneView)
        let newPosition = SCNVector3(node.position.x + Float(translation.x) * 0.001,
                                     node.position.y,
                                     node.position.z + Float(translation.y) * 0.001)
        node.position = newPosition
        
        gesture.setTranslation(CGPoint.zero, in: sceneView)
    }

    // MARK: - Обновление физического тела
    private func updatePhysicsBody(for node: SCNNode) {
        if let geometry = node.geometry {
            let shape = SCNPhysicsShape(geometry: geometry, options: nil)
            node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        }
    }

    // MARK: - Получение выбранного узла для манипуляций
    func getSelectedNode(from gesture: UIGestureRecognizer) -> SCNNode? {
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        if let node = hitResults.first?.node, node.parent != nil {
            return node
        }
        return nil
    }


}

extension UIColor {
    static var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.5)
    }
}
