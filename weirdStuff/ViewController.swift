//
//  ViewController.swift
//  weirdStuff
//
//  Created by Phuong Ngo on 8/7/18.
//  Copyright © 2018 Phuong Ngo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var currentNodesNum : Int = 1
    var dotNodes = [SCNNode]()
    var lineNodes = [SCNNode]()
    var labels = [UILabel]()
    var lengths = [Float]()
    var line_node : SCNNode?
    var startNode : SCNNode? = nil
    var continueFlag : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        continueFlag = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let hitPosition = doHitTest() {
            addDot(at: hitPosition)
        }
    }
    
    func placeLabel(dot1 : SCNNode, dot2 : SCNNode) {
        let midPoint = SCNVector3(x: (dot1.position.x+dot2.position.x)/2,
                                  y: (dot1.position.y+dot2.position.y)/2,
                                  z: (dot1.position.z+dot2.position.z)/2)
        let setlocation = self.sceneView.projectPoint(midPoint)
        
//        print("\(setlocation) \(self.navigationController?.navigationBar.frame.size.height)")
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .black
        label.backgroundColor = .white
        
        let topGutter : CGFloat = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height
        
        label.center = CGPoint(x: Double(setlocation.x), y: Double(setlocation.y) +  Double(topGutter))
        label.textAlignment = .center
        label.text = "\(calculate(dot1 : dot1, dot2 : dot2)) cm"
        
        self.view.addSubview(label)
        labels.append(label)
    }
    
    // calculate the distance between two dots
    func calculate(dot1 : SCNNode, dot2 : SCNNode) -> Float {
        let length = sqrt(pow(abs(dot1.position.x-dot2.position.x),2)+pow(abs(dot1.position.y-dot2.position.y),2)+pow(abs(dot1.position.z-dot2.position.z),2))
        let finalLength = length*100
        return finalLength
    }
    
    // do hitTest from a default position in the center
    func doHitTest() -> SCNVector3? {
        let dotLocation = CGPoint(x: UIScreen.main.bounds.size.width*0.5,y: UIScreen.main.bounds.size.height*0.5-50)
        let results = sceneView.hitTest(dotLocation, types: .featurePoint)
        if let hitPoint = results.first {
            let hitResult = self.positionTransform(transform: hitPoint.worldTransform)
            return hitResult
        }
        return nil
    }
    
    // render a dot
    func addDot(at hitResult : SCNVector3) {
        let dotGeometry = SCNSphere(radius: 0.002)
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.white
        dotGeometry.materials = [material]
        
        
        let dotNode = SCNNode(geometry: dotGeometry)
        dotNode.position = SCNVector3(x: hitResult.x, y: hitResult.y, z: hitResult.z)
        sceneView.scene.rootNode.addChildNode(dotNode)
        dotNodes.append(dotNode)
    }
    
    // some shit for line rendering
    func positionTransform (transform : matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    // line rendering
    func drawLine(from pos1 : SCNVector3, to pos2 : SCNVector3) -> SCNNode {
        let line = lineFrom(vector : pos1, toVector : pos2)
        let lineInBetween = SCNNode(geometry : line)
        return lineInBetween
    }
    
    // line rendering
    func lineFrom(vector vector1 : SCNVector3, toVector vector2 : SCNVector3) -> SCNGeometry {
        let indices : [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            //self.label?.removeFromSuperview()
            for i in self.labels {
                i.removeFromSuperview()
            }
            
            if self.dotNodes.count != 0 && self.continueFlag != false {
                self.startNode = self.dotNodes[self.currentNodesNum-1]
            } else {
                self.startNode = nil
                self.updateLabelPosition()
                self.line_node?.removeFromParentNode()
            }
            
            if self.startNode != nil {
                guard let currentPosition = self.doHitTest(),
                    let start = self.startNode else {
                        return
                }
                
            if self.dotNodes.count > self.currentNodesNum {
                print("dots updated")
                self.currentNodesNum = self.dotNodes.count
                self.lineNodes.append(self.line_node!)
                self.placeLabel(dot1: self.dotNodes[self.currentNodesNum-2], dot2: self.dotNodes[self.currentNodesNum-1])
                //print("new label created")
                self.sceneView.scene.rootNode.addChildNode(self.lineNodes[self.currentNodesNum-2])
                //print(self.labels)
            } else {
                self.line_node?.removeFromParentNode()
            }
            
                self.updateLabelPosition()
                
            self.line_node = self.drawLine(from : currentPosition, to : start.position)
            self.sceneView.scene.rootNode.addChildNode(self.line_node!)
            }
        }
    }
    
    // update the label position
    func updateLabelPosition() {
        if currentNodesNum >= 2 {
            for i in stride(from: 2, to: currentNodesNum+1, by: 1){
                self.placeLabel(dot1: dotNodes[i-2], dot2: dotNodes[i-1])
            }
        }
    }
}
