//
//  Plane.swift
//  AR Playground
//
//  Created by Aivant Goyal on 8/1/17.
//  Copyright © 2017 aivantgoyal. All rights reserved.
//

import ARKit
import SceneKit

class Plane : SCNNode{
    
    var anchor : ARPlaneAnchor!
    var planeGeometry : SCNPlane!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(withAnchor anchor: ARPlaneAnchor) {
        super.init()

        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        print("Found Plane of extent width: \(anchor.extent.x) height: \(anchor.extent.z)")

        let material = SCNMaterial()
        material.diffuse.contents = #imageLiteral(resourceName: "Tron Grid")
        planeGeometry.materials = [material]
        
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x,0, anchor.center.z)
        print("Creating Plane Anchor at position (x: \(anchor.center.x),y: \(anchor.center.y), z:\(anchor.center.z)")
        planeNode.transform = SCNMatrix4MakeRotation( .pi/2, 1.0, 0.0, 0.0)
        
        setTextureScale()
        self.addChildNode(planeNode)
    }
    
    func update(anchor: ARPlaneAnchor){
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        setTextureScale()
    }
    
    func setTextureScale(){
        let width = Float(planeGeometry.width)
        let height = Float(planeGeometry.height)
        
        let material = planeGeometry.materials.first!
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
    
}
