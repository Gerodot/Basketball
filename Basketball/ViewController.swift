//
//  ViewController.swift
//  Basketball
//
//  Created by Gerodot on 19.03.2022.
//

import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: -Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: -Properites
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    var isHoobAdded = false {
        didSet {
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    
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
        
        //Detect planes
        configuration.planeDetection = .vertical
        
        // Add people occlusion
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
        
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
    
    
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {return}
        
        guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {return}
        
        if isHoobAdded {
            
            // Add basketballs
            
        } else {
            
            //Get hoobNode and set coordinats to the point user touch
            let hoobNode = getHoobNode()
            hoobNode.simdTransform = result.worldTransform
            
            // Hoobnode make is vertical
            hoobNode.eulerAngles.x -= .pi / 2
            //Add hoob to planeAnchor
            sceneView.scene.rootNode.addChildNode(hoobNode)
            
            isHoobAdded = true
            
            print(#line,#function,result)
        }
    }
}
