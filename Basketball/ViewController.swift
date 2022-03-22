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
            // configuration.planeDetection = []
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
        configuration.planeDetection = [.vertical, .horizontal]
        
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
    
    func getBall () -> SCNNode? {
        // Get current frame
        guard let frame = sceneView.session.currentFrame else {return nil}
        
        // Get camera transorm
        let cameraTtransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTtransform)
        
        // Create ball geometry
        let ball = SCNSphere(radius: 0.125)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "basketball")
        
        // Create ball node
        let ballNode = SCNNode(geometry: ball)
        
        // Add physics body
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        
        // Calculate matrix force for pushing ball
        let power = Float(5)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x,y,z)
        
        // Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        
        // Assign camera position to ball
        ballNode.simdTransform = frame.camera.transform
        
        return ballNode
    }
    
    func getHoopNode () -> SCNNode {
        
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        
        let hoopNode = scene.rootNode.clone()
        
        hoopNode.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(
                node: hoopNode,
                options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
            )
        )
        
        return hoopNode
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
        
        // Add physics for plane nodes
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape:SCNPhysicsShape(geometry: plane))
        
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
        
        if isHoobAdded {
            planeNode.opacity = 0
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {return}
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return} // removeed alignment property сondition
       
        // Add ht hoob to the detected vertical plane
        node.addChildNode(getPlane(for: planeAnchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // guard let planeAnhcor = anchor as? ARPlaneAnchor, planeAnhcor.alignment == .vertical else {return}
        guard let planeAnhcor = anchor as? ARPlaneAnchor else {return} // removeed alignment property сondition
        
        // Update plane node
        updatePlaneNode(node, for: planeAnhcor)
    }
    
    
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        if isHoobAdded {
            
            // Get ball node
            guard let ballNode = getBall() else {return}
            
            // Add ball on the camera position
            sceneView.scene.rootNode.addChildNode(ballNode)
        } else {
            
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {return}
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {return}
            
            
            //Get hoobNode and set coordinats to the point user touch
            let hoobNode = getHoopNode()
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
