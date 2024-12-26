import UIKit
import ARKit
import SceneKit

class UIElements: UIViewController {

    public var arrowNode: SCNNode!
    public var statusLabel: UILabel!
    
    //Status label
    func setupStatusLabel(sceneView: ARSCNView) {
        statusLabel = UILabel()
        statusLabel.text = "Move your camera to find anchors..."
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        sceneView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: sceneView.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        startBlinking(label: statusLabel)
    }

    func startBlinking(label: UILabel) {
        // Анимация изменения прозрачности
        UIView.animate(withDuration: 0.8, // Длительность анимации
                       delay: 0.0,
                       options: [.autoreverse, .repeat], // Повторение и возврат
                       animations: {
            label.alpha = 0.0 // Прозрачность до 0
        }, completion: { _ in
            label.alpha = 1.0 // Восстановление прозрачности
        })
    }

    //Navigation arrow
    func setupArrow(sceneView: ARSCNView) {
        // Создаём 3D стрелку
        arrowNode = create2DArrow()

        guard let cameraNode = sceneView.pointOfView else { return }
        cameraNode.addChildNode(arrowNode!)

        // Добавляем мигание
        startBlinking(node: arrowNode!)
    }
    
    func create2DArrow() -> SCNNode {
        // Создаем путь для треугольника (стрелки) с помощью UIBezierPath
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 0, y: 0.1)) // Вершина стрелки (наконечник)
        arrowPath.addLine(to: CGPoint(x: -0.05, y: -0.05)) // Левая часть стрелки
        arrowPath.addLine(to: CGPoint(x: 0.05, y: -0.05)) // Правая часть стрелки
        arrowPath.close() // Закрытие пути для завершения треугольника

        // Создаем SCNShape из UIBezierPath
        let arrowGeometry = SCNShape(path: arrowPath, extrusionDepth: 0.01)
        
        // Настроим материал для стрелки
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white // Цвет стрелки
        arrowGeometry.materials = [material]
        
        // Создаем узел для стрелки
        let arrowNode = SCNNode(geometry: arrowGeometry)
        
        arrowNode.eulerAngles = SCNVector3(0, 0, 0)
        
        // Устанавливаем позицию стрелки
        arrowNode.position = SCNVector3(0, 0, -0.5)
        
        return arrowNode
    }



    func startBlinking(node: SCNNode) {
        // Анимация изменения прозрачности
        let fadeOut = SCNAction.fadeOpacity(to: 0.4, duration: 1) // Плавное исчезновение
        let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 1)  // Плавное появление
        let blinkSequence = SCNAction.sequence([fadeOut, fadeIn])   // Последовательность анимаций
        let repeatBlink = SCNAction.repeatForever(blinkSequence)   // Повторение анимации
        node.runAction(repeatBlink)                                // Запуск анимации
    }

    //Upodatr arr dir
    func updateArrowDirection(to position: SCNVector3, sceneView: ARSCNView) {
        guard let cameraNode = sceneView.pointOfView else { return }

        // Рассчитываем вектор от стрелки к точке
        let direction = SCNVector3(position.x - cameraNode.position.x,
                                   position.y - cameraNode.position.y,
                                   position.z - cameraNode.position.z)
        
        // Вычисляем угол поворота для стрелки
        let angle = atan2(direction.y, direction.x) - .pi / 2 // Вычисляем угол на основе координат X и Y
        
        // Поворачиваем стрелку
        arrowNode?.eulerAngles.z = angle
        
        // Устанавливаем позицию стрелки
        arrowNode?.position = SCNVector3(0, -0.075, -0.5) // Помещаем стрелку перед камерой
        
        // Вычисляем расстояние между камерой и целью
        //let distance = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
    
    }
    
    func isNodeVisible(node: SCNNode, in sceneView: ARSCNView) -> Bool {
        // Получаем камеру
        guard let cameraNode = sceneView.pointOfView else { return false }
        
        // Проверяем, находится ли узел внутри поля зрения камеры
        return sceneView.isNode(node, insideFrustumOf: cameraNode)
    }
    
    // Метод для отрисовки точки
    func drawPoint(at position: SCNVector3, sceneView: ARSCNView) {

        if let existingPointNode = sceneView.scene.rootNode.childNode(withName: "positionPoint", recursively: true) {
            existingPointNode.position = position // Обновляем позицию точки
        } else {
            // Создаем новую точку
            let sphereGeometry = SCNSphere(radius: 0.01) // Маленькая сфера
            sphereGeometry.firstMaterial?.diffuse.contents = UIColor.white
            
            let pointNode = SCNNode(geometry: sphereGeometry)
            pointNode.name = "positionPoint" // Устанавливаем имя для поиска
            pointNode.position = position
            
            // Добавляем точку в сцену
            sceneView.scene.rootNode.addChildNode(pointNode)
        }
    }

    
}
