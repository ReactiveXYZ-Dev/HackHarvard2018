/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom `ARSCNView` configured for the requirements of this project.
*/

import Foundation
import ARKit

class VirtualObjectARView: ARSCNView {

    // MARK: Position Testing
    
    var mode: String = "guaguale"
    
    /// Hit tests against the `sceneView` to find an object at the provided point.
    func virtualObject(at point: CGPoint) -> VirtualObject? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return VirtualObject.existingObjectContainingNode(result.node)
        }.first
    }
    
    func whitePaperObjects(at point: CGPoint) -> [SCNNode] {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return result.node
        }.filter { $0.name == "white-paper" }
        
    }
    
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal, .vertical]) -> ARHitTestResult? {
        
        // Perform the hit test.
        let results = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane, .estimatedHorizontalPlane])
        
        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }),
            let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
            return existingPlaneUsingGeometryResult
        }
        
        if infinitePlane {
            
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            let infinitePlaneResults = hitTest(point, types: .existingPlane)
            
            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                    if planeAnchor.alignment == .vertical {
                        // Return the first vertical plane hit test result.
                        return infinitePlaneResult
                    } else {
                        // For horizontal planes we only want to return a hit test result
                        // if it is close to the current object's position.
                        if let objectY = objectPosition?.y {
                            let planeY = infinitePlaneResult.worldTransform.translation.y
                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                                return infinitePlaneResult
                            }
                        } else {
                            return infinitePlaneResult
                        }
                    }
                }
            }
        }
        
        // 3. As a final fallback, check for a result on estimated planes.
        let vResult = results.first(where: { $0.type == .estimatedVerticalPlane })
        let hResult = results.first(where: { $0.type == .estimatedHorizontalPlane })
        switch (allowedAlignments.contains(.horizontal), allowedAlignments.contains(.vertical)) {
            case (true, false):
                return hResult
            case (false, true):
                // Allow fallback to horizontal because we assume that objects meant for vertical placement
                // (like a picture) can always be placed on a horizontal surface, too.
                return vResult ?? hResult
            case (true, true):
                if hResult != nil && vResult != nil {
                    return hResult!.distance < vResult!.distance ? hResult! : vResult!
                } else {
                    return hResult ?? vResult
                }
            default:
                return nil
        }
    }
    
    var gameTimer: Timer!
    var countdown: Int = 1 // 1 <= countdown <= 170
    var reduceCountdown: Bool = false
    
    var currentTrackingObject: VirtualObject?
    var totalWhitespaces: Int = 25 * 25

    // - MARK: Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for object: VirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        
        currentTrackingObject = object
        
        if self.mode == "guaguale" {
            //======== Create the white paper view
            let frameNode = object.childNodes[0].childNodes[0]
            let xSize = frameNode.boundingBox.max.x - frameNode.boundingBox.min.x
            let zSize = frameNode.boundingBox.max.y - frameNode.boundingBox.min.y
            let xCount = 25
            let zCount = 25
            let xIncr = xSize / Float(xCount);
            let zIncr = zSize / Float(zCount);
            
            if object.supportScraping {
                for x in 0...xCount {
                    for z in 0...zCount {
                        let whitePaper = SCNNode(geometry: SCNPlane(width: CGFloat(xIncr), height: CGFloat(zIncr)))
                        whitePaper.name = "white-paper"
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.white
                        whitePaper.geometry?.materials = [material]
                        switch object.currentAlignment {
                        case .horizontal:
                            whitePaper.position = SCNVector3(x: Float(x)*xIncr-xSize/2, y: 0, z: Float(z)*zIncr-zSize/2)
                            whitePaper.position.y += 0.01
                            whitePaper.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
                            break
                        case .vertical:
                            whitePaper.position = SCNVector3(x: Float(x)*xIncr-xSize/2, y: 0, z: Float(z)*zIncr-zSize/2)
                            whitePaper.position.y += 0.01
                            whitePaper.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
                            break
                        default:
                            break
                        }
                        object.addChildNode(whitePaper)
                    }
                }
                
            }
        
//        let moveUp = SCNAction.moveBy(x: 0, y: 0, z: 1, duration: 3)
//        moveUp.timingMode = .easeInEaseOut
//        let moveDown = SCNAction.moveBy(x: 0, y: 0, z: -1, duration: 3)
//        moveDown.timingMode = .easeInEaseOut
//        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        
        //cover.runAction(SCNAction.repeatForever(moveSequence))
        
        
        //======== Finish creating the white paper view

        session.add(anchor: newAnchor)
        
    }
    }
    
    func initializePaintingDestruction() {
        let object = currentTrackingObject!
        let frameNode = object.childNodes[0].childNodes[0]
        let xSize = frameNode.boundingBox.max.x - frameNode.boundingBox.min.x
        let zSize = frameNode.boundingBox.max.y - frameNode.boundingBox.min.y
        let xCount = 25
        let zCount = 25
        let xIncr = xSize / Float(xCount);
        let zIncr = zSize / Float(zCount);
        // Item cover
        let cover = SCNNode(geometry: SCNPlane(width: CGFloat(xSize), height: CGFloat(zSize)))
        cover.name = "cover"
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "shredded1")
        
        cover.geometry?.materials = [material]
        cover.position = SCNVector3(0, 0.015, 0)
        cover.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
        object.addChildNode(cover)
        
        let cover2 = SCNNode(geometry: SCNPlane(width: CGFloat(xSize), height: CGFloat(zSize)))
        cover2.name = "cover-2"
        let material2 = SCNMaterial()
        cover2.geometry?.materials = [material2]
        cover2.position = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
        object.addChildNode(cover2)
        
        // Hide the image
        DispatchQueue.main.async {
            self.gameTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.reloadShreddedImages), userInfo: ["moving": cover, "static": cover2], repeats: true)
        }
        
        // Item shredded effect
        for _ in 1...600 {
            // create random white boxes and spheres at random locations beneath the cover
            let isBox = Bool.random()
            
            var node: SCNNode
            if isBox {
                node = SCNNode(geometry: SCNBox(width: 0.003, height: 0.003, length: 0.003, chamferRadius: 0))
            } else {
                node = SCNNode(geometry: SCNSphere(radius: 0.003))
            }
            
            let xEps = Float.random(in: (-xSize/2)...(xSize/2))
            let zEps = Float.random(in: 0..<0.2)
            node.position = SCNVector3(xEps, 0, zSize/2 + zEps)
            
            // configure its animation
            let zMoveEps = Float.random(in: 0..<0.3)
            let zMoveDuration = Float.random(in: 2.5...6.5)
            
            let movedown = SCNAction.moveBy(x: 0, y: 0, z: CGFloat(zMoveEps), duration: TimeInterval(zMoveDuration))
            movedown.timingMode = .easeInEaseOut
            let fadeout = SCNAction.fadeOut(duration: 0.65)
            
            let moveup = SCNAction.moveBy(x: 0, y: 0, z: CGFloat(zMoveEps), duration: 0.2)
            let fadein = SCNAction.fadeIn(duration: 0.65)
            
            let moveSequence = SCNAction.sequence([movedown, fadeout, moveup, fadein])
            
            node.runAction(SCNAction.repeatForever(moveSequence))
            
            object.addChildNode(node)
        }
    }
    
    @objc func reloadShreddedImages(timer: Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
        let node = userInfo["moving"] as! SCNNode
        
        // update object image
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "shredded\(countdown)")
        
        // check and update countdown status
        if countdown >= 170 {
            reduceCountdown = true
        } else if countdown <= 1 {
            reduceCountdown = false
        }
        
        // update countdown
        if reduceCountdown {
            countdown -= 1
        } else {
            countdown += 1
        }
        
    }
    
    // - MARK: Lighting
    
    var lightingRootNode: SCNNode? {
        return scene.rootNode.childNode(withName: "lightingRootNode", recursively: true)
    }
    
    func setupDirectionalLighting(queue: DispatchQueue) {
        guard self.lightingRootNode == nil else {
            return
        }
        
        // Add directional lighting for dynamic highlights in addition to environment-based lighting.
        guard let lightingScene = SCNScene(named: "lighting.scn", inDirectory: "Models.scnassets", options: nil) else {
            print("Error setting up directional lights: Could not find lighting scene in resources.")
            return
        }
        
        let lightingRootNode = SCNNode()
        lightingRootNode.name = "lightingRootNode"
        
        for node in lightingScene.rootNode.childNodes where node.light != nil {
            lightingRootNode.addChildNode(node)
        }
        
        queue.async {
            self.scene.rootNode.addChildNode(lightingRootNode)
        }
    }
    
    func updateDirectionalLighting(intensity: CGFloat, queue: DispatchQueue) {
        guard let lightingRootNode = self.lightingRootNode else {
            return
        }
        
        queue.async {
            for node in lightingRootNode.childNodes {
                node.light?.intensity = intensity
            }
        }
    }
}

extension SCNView {
    /**
     Type conversion wrapper for original `unprojectPoint(_:)` method.
     Used in contexts where sticking to SIMD float3 type is helpful.
     */
    func unprojectPoint(_ point: float3) -> float3 {
        return float3(unprojectPoint(SCNVector3(point)))
    }
}
