import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    private var isAnchorVisible: Bool = false
    private var lastPos: SCNVector3?
    
    let UIE = UIElements()
    let model = OrangeModel()
    
    //Configuration on view load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Could not load AR Resources")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        
        sceneView.session.run(configuration)
    
        UIE.setupStatusLabel(sceneView: sceneView)
    }
    
    //when node adding firstly
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        print("Объект найден: \(imageAnchor.referenceImage.name ?? "без имени")")
        
        DispatchQueue.main.async {
            self.UIE.statusLabel.isHidden = true
            self.isAnchorVisible = true
            self.model.controlButtons.forEach { $0.isHidden = false }
        }
        
        let anchorPosition = SCNVector3(
            imageAnchor.transform.columns.3.x,
            imageAnchor.transform.columns.3.y,
            imageAnchor.transform.columns.3.z
        )
        
        model.addModel(node: node)
        
    }

    // when node removing
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        print("Объект удален: \(imageAnchor.referenceImage.name ?? "без имени")")
        
        DispatchQueue.main.async {
            self.UIE.statusLabel.isHidden = false
            self.isAnchorVisible = false
            self.model.controlButtons.forEach { $0.isHidden = true }
        }

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        //print("Позиция якоря: ", imageAnchor.transform.columns.3)
        
        DispatchQueue.main.async {
            if imageAnchor.isTracked {
                // если захват произошел
                self.UIE.statusLabel.isHidden = true
                self.isAnchorVisible = true
                self.UIE.arrowNode?.removeFromParentNode()
                self.model.controlButtons.forEach { $0.isHidden = false }
                
            } else {
                
                print("Объект потерян: \(imageAnchor.referenceImage.name ?? "без имени")")
                
                //если оьъект пропал
                let anchorPosition = SCNVector3(
                    imageAnchor.transform.columns.3.x,
                    imageAnchor.transform.columns.3.y,
                    imageAnchor.transform.columns.3.z
                )
                
                self.UIE.statusLabel.isHidden = false
                self.UIE.setupArrow(sceneView: self.sceneView)
                //self.UIE.drawPoint(at: anchorPosition, sceneView: self.sceneView)
                
                self.isAnchorVisible = false
                self.model.controlButtons.forEach { $0.isHidden = true }
                
                self.lastPos = anchorPosition
            }
        }
        
    }
    
    //update all time
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if var position = lastPos {
            self.UIE.updateArrowDirection(to: position, sceneView: sceneView)
            
            if isAnchorVisible(anchorPosition: position, sceneView: sceneView) {
                UIE.arrowNode.isHidden = true
            } else {
                UIE.arrowNode.isHidden = false
            }
        }

    }
    
    //Обработка нажатий
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, options: nil)
        if let result = hitTestResults.first {
            let node = result.node
            
            // Проверяем, является ли узел целевым
            if node.name == "orange" {
                model.onModelTouch(node: node)
            }
        }
        
    }
    
    // Вспом. функция видимости якоря
    func isAnchorVisible(anchorPosition: SCNVector3, sceneView: ARSCNView) -> Bool {

        // Создаем узел для проверки видимости
        let nodeToCheck = SCNNode()
        nodeToCheck.position = anchorPosition

        // Получаем камеру
        guard let cameraNode = sceneView.pointOfView else { return false }

        // Проверяем, находится ли узел внутри видимости камеры
        return sceneView.isNode(nodeToCheck, insideFrustumOf: cameraNode)
    }
    
}

