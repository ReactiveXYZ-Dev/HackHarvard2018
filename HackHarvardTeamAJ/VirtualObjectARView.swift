/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom `ARSCNView` configured for the requirements of this project.
*/

import Foundation
import ARKit

class VirtualObjectARView: ARSCNView {

    // MARK: Position Testing
    
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
    
    var artworkObject: VirtualObject!
    
    // - MARK: Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for object: VirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        artworkObject = object
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: artworkObject.simdWorldTransform)
        artworkObject.anchor = newAnchor
        
        //======== Create the white paper view
        let frameNode = artworkObject.childNodes[0].childNodes[0]
        let xSize = frameNode.boundingBox.max.x - frameNode.boundingBox.min.x
        let zSize = frameNode.boundingBox.max.y - frameNode.boundingBox.min.y
        let xCount = 25
        let zCount = 25
        let xIncr = xSize / Float(xCount);
        let zIncr = zSize / Float(zCount);
        
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
        
        cover = SCNNode(geometry: SCNPlane(width: CGFloat(xSize), height: CGFloat(zSize)))
        cover.name = "cover"
        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.red
//        material.transparent.contents = UIImage(color: UIColor(red: 255, green: 1, blue: 1, alpha: 0.4), size: CGSize(width: CGFloat(xSize), height: CGFloat(zSize)/2))

        cover.geometry?.materials = [material]
//        cover.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
//        cover.physicsBody?.mass = 5.0
        cover.position = SCNVector3(x: 0, y: 0.015, z: 0)
        cover.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
        artworkObject.addChildNode(cover)
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.actionTimer), userInfo: nil, repeats: true)
        }
        
        
//        let cover2 = SCNNode(geometry: SCNPlane(width: CGFloat(xSize), height: CGFloat(zSize)))
//        cover2.name = "cover2"
//        let material2 = SCNMaterial()
//        let croprect = CGRect(x: 0.0, y: 0.0, width: 2448.0, height: 2000.0)
//
//        cover2.geometry?.materials = [material2]
//
//        cover2.position = SCNVector3(x: 0, y: 0.02, z: 0)
//        cover2.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0)
//        object.addChildNode(cover2)
        
        
//        let moveUp = SCNAction.moveBy(x: 0, y: 0, z: 0.5, duration: 3)
//        moveUp.timingMode = .easeInEaseOut;
//        let moveDown = SCNAction.moveBy(x: 0, y: 0, z: -0.5, duration: 3)
//        moveDown.timingMode = .easeInEaseOut;
//        let moveSequence = SCNAction.sequence([moveUp,moveDown])
//        let moveLoop = SCNAction.repeatForever(moveSequence)
//        cover.runAction(moveLoop)
        
        //======== Finish creating the white paper view

        session.add(anchor: newAnchor)
        
    }
    
    var cover: SCNNode!
    
    var t_count: CGFloat = 0.0
    
    var t_count_increase = true
    
    @objc func actionTimer() {
        // called every so often by the interval we defined above
//        DispatchQueue.main.async {
//
//        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        let imageHeight = UIImage(named: "painting_DIFFUSE")!.size.height
        let imageWidth = UIImage(named: "painting_DIFFUSE")!.size.width
        let croprect = CGRect(x: 0.0, y: 0.0, width: imageWidth, height: imageHeight - 20 * t_count)
        
        if let image = UIImage(named: "painting_DIFFUSE")?.cgImage?.cropping(to: croprect) {
            cover.geometry?.firstMaterial?.diffuse.contents = image
            cover.geometry?.firstMaterial?.diffuse.intensity = 1.0
//            SCNTransaction.commit()
        }
        
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = 0.1
        
        cover.scale = SCNVector3Make(1.0, 1.0, Float(1 - (20 * t_count) / imageHeight))
        print(">>> scale >>> \(cover.scale)")
        let frameNode = artworkObject.childNodes[0].childNodes[0]
        let zSize = frameNode.boundingBox.max.y - frameNode.boundingBox.min.y
        cover.position = SCNVector3(x: 0, y: 0.015, z: zSize * Float((20 * t_count) / imageHeight))
        SCNTransaction.commit()
        
        if t_count_increase {
            t_count += 1
        } else {
            t_count -= 1
        }
        
        if t_count >= 30 {
            t_count_increase = false
        }
        
        if t_count <= 0 {
            t_count_increase = true
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

extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
