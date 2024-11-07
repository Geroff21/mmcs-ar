import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var itemCount: UILabel! // UILabel для отображения количества объектов

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = []
        setupGestures()
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        updateObjectCount()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Обработка обнаруженной поверхности
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // Здесь вы можете добавить действия, когда поверхность найдена
        }
    }

    // MARK: - Настройка жестов
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        sceneView.addGestureRecognizer(longPressGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
    }

    // MARK: - Добавление куба
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if let result = hitTestResults.first {
            // Создаем новый куб и добавляем его в сцену
            let cubeSize: Float = 0.1 // Размер куба
            let cube = SCNBox(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = randomColor()
            cube.materials = [material]
            
            let node = SCNNode(geometry: cube)
            node.position = SCNVector3(result.worldTransform.columns.3.x,
                                       result.worldTransform.columns.3.y + (cubeSize / 2.0), // Поднимаем куб над поверхностью
                                       result.worldTransform.columns.3.z)
            
            // Настройка физического тела для коллизий
            node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            node.physicsBody?.categoryBitMask = 1
            node.physicsBody?.contactTestBitMask = 1
            node.physicsBody?.collisionBitMask = 1
            
            // Добавление куба в сцену
            sceneView.scene.rootNode.addChildNode(node)
            
            updateObjectCount()
        }
    }


    // MARK: - Удаление куба
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: nil)
            
            if let hitResult = hitResults.first, hitResult.node.parent != nil {
                hitResult.node.removeFromParentNode()
                updateObjectCount()
            }
        }
    }

    // MARK: - Обновление количества объектов
    func updateObjectCount() {
        let cubeCount = sceneView.scene.rootNode.childNodes.filter { $0.geometry is SCNBox }.count
        itemCount.text = "Objects: \(cubeCount)"
    }

    // MARK: - Поворот куба
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

    // MARK: - Масштабирование куба
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)

        if let hitResult = hitResults.first {
            let node = hitResult.node
            
            if node.geometry is SCNBox { // Убедитесь, что это куб
                if gesture.state == .changed {
                    // Масштабируем кубик на основе величины жеста
                    let scale = Float(gesture.scale) // Приведение gesture.scale к Float
                    
                    // Изменяем масштаб
                    let newScale = SCNVector3(
                        node.scale.x * scale,
                        node.scale.y * scale,
                        node.scale.z * scale
                    )
                    
                    // Обновляем масштаб кубика
                    node.scale = newScale
                    
                    // Обновляем физическое тело
                    updatePhysicsBody(for: node)
                    
                    gesture.scale = 1.0 // Сбрасываем значение жеста, чтобы оно не накапливалось
                }
            }
        }
    }

    // Метод для обновления физического тела
    private func updatePhysicsBody(for node: SCNNode) {
        if let geometry = node.geometry as? SCNBox {
            
            // Создаем новую физическую форму на основе нового размера
            let shape = SCNPhysicsShape(geometry: geometry, options: nil)
            node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            
            node.physicsBody?.categoryBitMask = 1
            node.physicsBody?.collisionBitMask = 1
            node.physicsBody?.contactTestBitMask = 1
            node.physicsBody?.restitution = 0.5
            node.physicsBody?.friction = 0.5
        }
    }

    // MARK: - Перемещение куба
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let node = getSelectedNode(from: gesture) else { return }
        
        let translation = gesture.translation(in: sceneView)
        let newPosition = SCNVector3(node.position.x + Float(translation.x) * 0.001,
                                     node.position.y,
                                     node.position.z + Float(translation.y) * 0.001)
        node.position = newPosition
        
        gesture.setTranslation(CGPoint.zero, in: sceneView)
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
    
    // MARK: - Генерация случайного цвета
    func randomColor() -> UIColor {
        let red = CGFloat(arc4random() % 256) / 255.0
        let green = CGFloat(arc4random() % 256) / 255.0
        let blue = CGFloat(arc4random() % 256) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    // MARK: - Очистка сцены
    @IBAction func clearScene(_ sender: UIButton) {
        print("Clear button tapped")
        for node in sceneView.scene.rootNode.childNodes {
            if node.geometry is SCNBox { // Удаляем только кубы
                node.removeFromParentNode()
            }
        }
        updateObjectCount() // Обновляем количество объектов
    }
    
    // Метод для изменения цвета
    func changeColor(to color: UIColor, for node: SCNNode) {
        node.geometry?.firstMaterial?.diffuse.contents = color
    }

    // Изменение цвета при столкновении
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB

        // Проверяем, являются ли оба объекта кубами
        if let geometryA = nodeA.geometry, let geometryB = nodeB.geometry, geometryA is SCNBox && geometryB is SCNBox {
            // Меняем цвет на черный
            changeColor(to: UIColor.black, for: nodeA)
            changeColor(to: UIColor.black, for: nodeB)
        }
    }
    func changeColorAndDisablePhysics(to color: UIColor, for node: SCNNode) {
        node.physicsBody?.isAffectedByGravity = false
        changeColor(to: color, for: node)
        node.physicsBody?.isAffectedByGravity = true
    }
}

