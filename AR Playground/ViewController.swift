//
//  ViewController.swift
//  AR Playground
//
//  Created by Aivant Goyal on 8/1/17.
//  Copyright © 2017 aivantgoyal. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ReplayKit


class ViewController: UIViewController {

    struct PhysicsCategory {
        static let sphere    : Int = 3
        static let plane     : Int = 2
        static let floor     : Int = 1
        
    }
    
    @IBOutlet var sceneView: ARSCNView!
    var planes = [UUID : SCNNode]()
    var isInGameMode = false
    var isRecording = false
    
    
    //MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Configure and run the session
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        

        
    }
    
    var firstOpenFlag = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard firstOpenFlag else { return }
        let alertController = UIAlertController(title: "Welcome to the AR Playground", message: "Move around and let your phone recognize horizontal surfaces. When you're ready to test out the physics, tap and hold the screen to switch to game mode. Finally, tapping with three fingers will start a screen recording. Enjoy!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            
        }))
        present(alertController, animated: true, completion: nil)
        firstOpenFlag = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: Setup Functions
    
    func setupScene(){
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.scene.rootNode.addChildNode(createFloor())
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func setupGestureRecognizers(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        let twoFingerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerTap(sender:)))
        let threeFingerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap(sender:)))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tapRecognizer.numberOfTouchesRequired = 1
        twoFingerTapRecognizer.numberOfTouchesRequired = 2
        threeFingerTapRecognizer.numberOfTouchesRequired = 3
        sceneView.addGestureRecognizer(threeFingerTapRecognizer)
        sceneView.addGestureRecognizer(twoFingerTapRecognizer)
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.addGestureRecognizer(longPressRecognizer)
    }
    
    // MARK: UI Creation Functions

    func createFloor() -> SCNNode{
        let geometry = SCNBox(width: 20, height: 0.5, length: 20, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        geometry.materials = [material]
        material.isDoubleSided = true
        let basePlane = SCNNode(geometry: geometry)
        basePlane.position = SCNVector3Make(0, -10, 0)
        basePlane.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        basePlane.physicsBody?.contactTestBitMask = PhysicsCategory.floor
        return basePlane
    }
    
    func createPlane(forAnchor anchor: ARPlaneAnchor) -> SCNNode {
        // Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))

        // Create the plane material
        let planeImage = #imageLiteral(resourceName: "Tron Grid")
        let material = SCNMaterial()
        material.diffuse.contents = planeImage
        material.isDoubleSided = true
        plane.materials = [material]
        
        // Create a node with the plane geometry we created
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.contactTestBitMask = PhysicsCategory.plane
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        return planeNode
    }
    
    func createSphere(atPosition position: SCNVector3?) -> SCNNode {
        var insertPosition : SCNVector3!
        if position == nil {
            let localPosition = SCNVector3(0, 0, -0.5)
            insertPosition = sceneView.pointOfView!.convertPosition(localPosition, to: nil)
            
        }else{
            insertPosition = position
        }
        
        let geometry = SCNSphere(radius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.random()
        material.isDoubleSided = true
        geometry.materials = [material]
        
        let sphereNode = SCNNode(geometry: geometry)
        sphereNode.position = insertPosition
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.mass = 2.0
        sphereNode.physicsBody = physicsBody
        sphereNode.physicsBody?.contactTestBitMask  = PhysicsCategory.sphere
        
        return sphereNode;
    }
    
    //MARK: Handle Gestures
    
    @objc func handleTap(sender: UITapGestureRecognizer){
        guard isInGameMode else { return }
        print("Handling One Finger Tap; Creating Sphere above plane")
        let tapPoint = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        guard hitTestResults.count > 0 else {
            print("Found No Hit Test Results")
            handleTwoFingerTap(sender: sender)
            return
        }
        let hitResult = hitTestResults.first!
        let hit = hitResult.worldTransform.columns.3
        let insertionOffset : Float = 0.5
        let position = SCNVector3Make(hit.x ,hit.y + insertionOffset, hit.z)
        let sphereNode = createSphere(atPosition: position)
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    @objc func handleTwoFingerTap(sender: UITapGestureRecognizer){
        guard isInGameMode else { return }
        print("Handling Two Finger Tap; Creating Sphere in front of Camera")
        let sphereNode = createSphere(atPosition: nil)
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    @objc func handleThreeFingerTap(sender: UITapGestureRecognizer){
        if isRecording {
            RPScreenRecorder.shared().stopRecording(handler: { (previewController, error) in
                guard error == nil else { print("Error in stopping recording: \(error!.localizedDescription)"); return}
                guard let previewController = previewController else { print("Preview Controller is nil"); return}
                print("Successfully Stopped Recording")
                self.isRecording = false
                previewController.previewControllerDelegate = self
                self.present(previewController, animated: true, completion: nil)
            })
        }else{
            if RPScreenRecorder.shared().isAvailable {
                print("Screen Recording Available")
                let alertController = UIAlertController(title: "Video Recording", message: "You are now starting a screen recording. Tap with three fingers to finish.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                    RPScreenRecorder.shared().startRecording() { (error: Error?) -> Void in
                        if error == nil { // Recording has started
                            print("Recording Successfully Started")
                            self.isRecording = true
                        } else {
                            print("Error in Starting to Record: \(error!.localizedDescription)")
                            // Handle error
                        }
                    }
                }))
                present(alertController, animated: true, completion: nil)
            } else {
                print("Recording Unavailable")
                // Display UI for recording being unavailable
            }
        }
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer){
        guard sender.state == .began && !isInGameMode else { return }
        print("Handling Long Press; Switching to game mode")
        let configuration = sceneView.session.configuration as! ARWorldTrackingSessionConfiguration
        configuration.planeDetection = []
        sceneView.session.run(configuration)
        isInGameMode = true
        
        let alertController = UIAlertController(title: "Switching to Game Mode!", message: "Tap on a plane to drop a ball on it. Tapping elsewhere or tapping with two fingers will simply drop a ball in front of you. Have Fun!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    
}

extension ViewController : SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody!.contactTestBitMask == PhysicsCategory.floor && contact.nodeB.physicsBody!.contactTestBitMask == PhysicsCategory.sphere{
            print("Detected Sphere falling on floor")
            contact.nodeB.removeFromParentNode()

        } else if contact.nodeB.physicsBody!.contactTestBitMask == PhysicsCategory.floor && contact.nodeA.physicsBody!.contactTestBitMask == PhysicsCategory.sphere {
            print("Detected Sphere falling on floor")
            contact.nodeA.removeFromParentNode()
        }
    }
}

extension ViewController : RPPreviewViewControllerDelegate{
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("Preview Controller Finished")
        dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        print("Preview Controller Finished With Activity Types")
        dismiss(animated: true, completion: nil)
    }
}



extension ViewController : ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor{
            print("Added Plane Anchor")
            let newPlane = createPlane(forAnchor: planeAnchor)
            planes[anchor.identifier] = newPlane
            node.addChildNode(newPlane)
        }else{
            print("Added other Anchor")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let _ = planes[anchor.identifier], let anchor = anchor as? ARPlaneAnchor{
            node.enumerateChildNodes({ (childNode, _) in
                childNode.removeFromParentNode()
            })
            node.addChildNode(createPlane(forAnchor: anchor))
        }else{
            print("Updated Other Node")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let _ = planes[anchor.identifier] {
            planes.removeValue(forKey: anchor.identifier)
            print("Removed Plane Node")
        }else{
            print("Removed Different Node")
        }
        
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Camera Not Available")
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                print("Camera Tracking State Limited Due to Excessive Motion")
            case .initializing:
                print("Camera Tracking State Limited Due to Initalization")
            case .insufficientFeatures:
                print("Camera Tracking State Limited Due to Insufficient Features")
            case .none:
                print("Camera Tracking State Limited For No Reason")

            }
        case .normal:
            print("Camera Tracking State Normal")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed with error: \(error.localizedDescription)")
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session Interrupted")
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session no longer being interrupted")
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

