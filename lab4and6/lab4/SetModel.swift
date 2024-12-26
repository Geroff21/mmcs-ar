import UIKit
import ARKit
import SceneKit

class OrangeModel {
    
    public var controlButtons: [UIButton] = []
    public var currentTargetNode: SCNNode?
    
    func addModel(node: SCNNode) {
        // Загрузка 3D-модели
        if let scene = SCNScene(named: "art.scnassets/orange.scn") {
            if let modelNode = scene.rootNode.childNode(withName: "orange", recursively: true) {
                
                // Нормализуем модель
                let scaleFactor: Float = 0.025
                modelNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                        
                // Позиционируем модель относительно изображения-якоря
                modelNode.position = SCNVector3(0,0,scaleFactor * 2)
                modelNode.eulerAngles.x = -.pi / 2
                
                node.addChildNode(modelNode)
                
                let textNode = createTextNode(text: "Orange", position: SCNVector3(0, 0, 0.12))
                node.addChildNode(textNode)
                
                DispatchQueue.main.async {
                    self.addControlButtons(targetNode: modelNode)
                }
                
                currentTargetNode = modelNode
                
            } else {
                print("Error: Node with the specified name not found in the scene.")
            }
        } else {
            print("Error: Scene file not found.")
        }
    }
    
    func onModelTouch(node: SCNNode) {
        // Пульсация (увеличение и уменьшение размера)
        let scaleUp = SCNAction.scale(to: 0.027, duration: 0.2)
        let scaleDown = SCNAction.scale(to: 0.025, duration: 0.2)
        
        // Вращение
        let rotate = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 0.5)
        
        // Последовательность анимаций
        let pulseSequence = SCNAction.sequence([scaleUp, scaleDown])
        let fullAnimation = SCNAction.group([pulseSequence, rotate])
        
        // Действие с открытием ссылки
        let actionWithCompletion = SCNAction.run { _ in
            if let url = URL(string: "https://en.wikipedia.org/wiki/Orange_(fruit)") {
                UIApplication.shared.open(url)
            }
        }
        let finalAction = SCNAction.sequence([fullAnimation, actionWithCompletion])
        
        // Запуск действия для целевого узла
        node.runAction(finalAction)
    }
    
    // Функция для создания текстовой ноды
    func createTextNode(text: String, position: SCNVector3) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 0.1)
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = position
        textNode.scale = SCNVector3(0.05, 0.05, 0.05) // Масштабируем текст для уменьшения размера
        textNode.eulerAngles.x = -.pi / 2 // Поворачиваем текст, чтобы он отображался горизонтально
        
        return textNode
    }
    
    // Добавляем кнопки управления
    func addControlButtons(targetNode: SCNNode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootView = windowScene.windows.first?.rootViewController?.view else {
            print("Error: Could not retrieve root view.")
            return
        }
        
        let buttonSize: CGFloat = 60 // Размер кнопок
        
        // Кнопка вращения влево с текстом
        let leftButton = UIButton(frame: CGRect(x: 20, y: rootView.bounds.height - 120, width: buttonSize, height: buttonSize))
        leftButton.setTitle("◀️", for: .normal) // Текст стрелки влево
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold) // Большой жирный шрифт
        leftButton.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.7) // Фон с прозрачностью
        leftButton.layer.cornerRadius = buttonSize / 2 // Скругленные углы
        leftButton.addTarget(self, action: #selector(rotateLeft(_:)), for: .touchUpInside)
        rootView.addSubview(leftButton)
        
        // Кнопка вращения вправо с текстом
        let rightButton = UIButton(frame: CGRect(x: 110, y: rootView.bounds.height - 120, width: buttonSize, height: buttonSize))
        rightButton.setTitle("▶️", for: .normal) // Текст стрелки вправо
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold) // Большой жирный шрифт
        rightButton.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.7) // Фон с прозрачностью
        rightButton.layer.cornerRadius = buttonSize / 2 // Скругленные углы
        rightButton.addTarget(self, action: #selector(rotateRight(_:)), for: .touchUpInside)
        rootView.addSubview(rightButton)
        
        // Кнопка открытия сайта с текстом
        let infoButton = UIButton(frame: CGRect(x: rootView.bounds.width - 90, y: rootView.bounds.height - 120, width: buttonSize, height: buttonSize))
        infoButton.setTitle("🌍", for: .normal) // Текст для информации
        infoButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold) // Большой жирный шрифт
        infoButton.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.7) // Фон с прозрачностью
        infoButton.layer.cornerRadius = buttonSize / 2 // Скругленные углы
        infoButton.addTarget(self, action: #selector(openInfo(_:)), for: .touchUpInside)
        rootView.addSubview(infoButton)
        
        // Кнопка с информацией об объекте (Popup) с текстом
        let infoPopupButton = UIButton(frame: CGRect(x: rootView.bounds.width - 180, y: rootView.bounds.height - 120, width: buttonSize, height: buttonSize))
        infoPopupButton.setTitle("ℹ️", for: .normal) // Текст для Popup
        infoPopupButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold) // Большой жирный шрифт
        infoPopupButton.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.7) // Фон с прозрачностью
        infoPopupButton.layer.cornerRadius = buttonSize / 2 // Скругленные углы
        infoPopupButton.addTarget(self, action: #selector(showPopupInfo(_:)), for: .touchUpInside)
        rootView.addSubview(infoPopupButton)
        
        // Сохраняем узел для использования в действиях кнопок
        controlButtons = [leftButton, rightButton, infoButton, infoPopupButton]
    }
        
    @objc private func rotateLeft(_ sender: UIButton) {
        guard let targetNode = currentTargetNode else { return }
        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi / 8, duration: 0.2)
        targetNode.runAction(rotateAction)
    }
    
    @objc private func rotateRight(_ sender: UIButton) {
        guard let targetNode = currentTargetNode else { return }
        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: -CGFloat.pi / 8, duration: 0.2)
        targetNode.runAction(rotateAction)
    }
    
    @objc private func openInfo(_ sender: UIButton) {
        if let url = URL(string: "https://en.wikipedia.org/wiki/Orange_(fruit)") {
            UIApplication.shared.open(url)
        }
    }
    
    // Действие для показа Popup окна с информацией
    @objc private func showPopupInfo(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Информация об объекте", message: "Это 3D-объект, представляющий апельсин. Вы можете вращать его и взаимодействовать с ним.", preferredStyle: .alert)
        
        // Кнопка "ОК" для закрытия всплывающего окна
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Показываем alert
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alertController, animated: true, completion: nil)
        }
        
    }
}
