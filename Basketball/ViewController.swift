//
//  ViewController.swift
//  Basketball
//
//  Created by Gerodot on 19.03.2022.
//

import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: -UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //Detect planes
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Metods
    
    func getHoobNode () -> SCNNode {
        
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        
        let hoobNode = scene.rootNode.clone()
        
        // Hoobnode make is vertical
        hoobNode.eulerAngles.x -= .pi / 2
        
        return hoobNode
    }
    
    func getPlane (for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let plane = SCNPlane(width: CGFloat(extent.x),  height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        //Create 25% transpatrent plane node
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        //Rotate plane node
        planeNode.eulerAngles.x -= .pi / 2
        
        return planeNode
    }
    
    func updatePlaneNode (_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {return}
        
        //Change plane node center
        planeNode.simdPosition = anchor.center
        
        //Change plane node size
        let extent = anchor.extent
        plane.height = CGFloat(extent.z)
        plane.width = CGFloat(extent.x)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {return}
        
        
        //Add ht hoob to the detected vertical plane
        node.addChildNode(getPlane(for: planeAnchor))
        //getHoobNode()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnhcor = anchor as? ARPlaneAnchor, planeAnhcor.alignment == .vertical else {return}
        
        // Update plane node
        updatePlaneNode(node, for: planeAnhcor)
    }
}
