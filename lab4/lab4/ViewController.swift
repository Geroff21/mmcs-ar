import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.autoenablesDefaultLighting = true
        
        // Настройка AR Image Tracking Configuration
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Could not load AR Resources")
        }
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1 // Трек только одного изображения
        
        // Запуск сессии с конфигурацией трекинга изображений
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // Загрузка 3D-модели
        if let scene = SCNScene(named: "art.scnassets/orange.scn") {
            if let modelNode = scene.rootNode.childNode(withName: "orange", recursively: true) {
                
                // Нормализуем модель
                let scaleFactor: Float = 0.025 // Настраиваем коэффициент масштаба
                modelNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                        
                // Позиционируем модель относительно изображения-якоря
                let imagePosition = imageAnchor.transform.columns.3
                modelNode.position = SCNVector3(0,0,scaleFactor * 2)
                modelNode.eulerAngles.x = -.pi / 2
                
                node.addChildNode(modelNode) // Добавляем объект к узлу метки
                
                // Добавляем текстовую ноду под моделью
                let textNode = createTextNode(text: "Orange", position: SCNVector3(0, 0, 0.12))
                node.addChildNode(textNode) // Добавляем текстовый узел к тому же узлу, что и модель
            } else {
                print("Error: Node with the specified name not found in the scene.")
            }
        } else {
            print("Error: Scene file not found.")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        
        // Определение объекта по экранному касанию
        let hitTestResults = sceneView.hitTest(location, options: nil)
        if let result = hitTestResults.first {
            let node = result.node
            
            // Пульсация (увеличение и уменьшение размера)
            let scaleUp = SCNAction.scale(to: 0.027, duration: 0.2)
            let scaleDown = SCNAction.scale(to: 0.025, duration: 0.2)
            
            // Вращение
            let rotate = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 0.5)
            
            // Последовательность анимаций
            let pulseSequence = SCNAction.sequence([scaleUp, scaleDown])
            let fullAnimation = SCNAction.group([pulseSequence, rotate])
            
            // Блок завершения, который будет вызван после завершения анимации
            let actionWithCompletion = SCNAction.run { (node) in
                if let url = URL(string: "https://en.wikipedia.org/wiki/Orange_(fruit)") {
                    UIApplication.shared.open(url)
                }
            }

            // Добавление действия с завершением после всех анимаций
            let finalAction = SCNAction.sequence([fullAnimation, actionWithCompletion])
            
            node.runAction(finalAction)
        }
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
}

