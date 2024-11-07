//
//  ViewController.swift
//  lab1
//
//  Created by Matthew on 08.10.2024.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet var sceneView: ARSCNView!
    
    var analysis = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1
        labelView.layer.cornerRadius = 10

        sceneView.delegate = self
        sceneView.showsStatistics = true

        // 2
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        
        node.geometry?.firstMaterial?.fillMode = .fill
        node.geometry?.firstMaterial?.colorBufferWriteMask = .blue
        
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.01)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "stone")
        box.firstMaterial = material
        
        let c = SCNNode(geometry: box)
        
        c.name = "box"
        c.position = node.position
        c.position.y = c.position.y + 0.01
        
        node.addChildNode(c)
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)
            
            DispatchQueue.main.async {
                self.faceLabel.text = self.analysis
            }
            
        }
    }
    
    func expression(anchor: ARFaceAnchor) {
        // 1
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        self.analysis = ""

        // 2
        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.9 {
            self.analysis += "You are smiling. "
        }

        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Your cheeks are puffed. "
        }

        if tongue?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Don't stick your tongue out! "
        }
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}


