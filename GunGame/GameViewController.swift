//
//  GameViewController.swift
//  HitTheTree
//
//  Created by Brian Advent on 26.04.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController{
    
    let CategoryTree = 2
    let CategoryGoldRing = 4
    
    var sceneView:SCNView!
    var scene:SCNScene!
    var scenes: [String]!
    var currentScene = 0
    
    var ballNode:SCNNode!
//    var enemyNode:SCNNode?
    var enemyNodes:[[SCNNode]] = [[],[],[]]
    var selfieStickNode:SCNNode!
    
    var motion = MotionHelper()
    var motionForce = SCNVector3(0, 0, 0)
    
    var sounds:[String:SCNAudioSource] = [:]
    
    var leftKnob: UIImageView!
    var leftPad: UIImageView!
    var joystick: UIImageView!
    var pause: UIButton!
    var jump: UIButton!
    var score: UILabel!
//    var left:Bool = false
//    var right:Bool  = false
    
    override func viewDidLoad() {
        scenes = ["art.scnassets/MainScene.scn",
                  "art.scnassets/SceneTwo.scn",
                  "art.scnassets/SceneThree.scn",
                  "art.scnassets/SceneFour.scn",
                  "art.scnassets/SceneFive.scn",
                  "art.scnassets/SceneSix.scn",
                  "art.scnassets/SceneSeven.scn",
                  "art.scnassets/SceneEight.scn",
                  "art.scnassets/SceneNine.scn",
                  "art.scnassets/SceneTen.scn",
                  "art.scnassets/EndScene.scn"]
        setupScene()
        setupNodes()
        setupSounds()
        setupJoystick()
        if let saw = sounds["saw"] {
            ballNode.runAction(SCNAction.playAudio(saw, waitForCompletion: false))
        }
        pause = UIButton()
        pause.frame = CGRect(x: UIScreen.main.bounds.width - 55, y: 5, width: 50, height: 50)
        pause.setTitle("||", for: .normal)
        pause.layer.cornerRadius = 5
        pause.layer.borderColor = UIColor.white.cgColor
        pause.layer.borderWidth = 2
        pause.layer.masksToBounds = true
        pause.addTarget(self, action: #selector(paused), for: .touchUpInside)
        self.view.addSubview(pause)
        jump = UIButton()
        jump.setTitle("JUMP", for: .normal)
        jump.layer.cornerRadius = 5
        jump.layer.borderColor = UIColor.white.cgColor
        jump.layer.borderWidth = 2
        jump.layer.masksToBounds = true
        jump.frame = CGRect(x: (joystick.frame.width + 50) / 2, y:self.view.frame.height - (200 - 62.5), width: (joystick.frame.width - 100) / 2, height: 75)
        jump.addTarget(self, action: #selector(jumped), for: .touchUpInside)
        self.view.addSubview(jump)
        
        score = UILabel()
        score.frame = CGRect(x: UIScreen.main.bounds.width - 155, y: 5, width: 80, height: 50)
        score.text = "\(currentScene + 1)/10"
        self.view.addSubview(score)
    }
    
    func setupScene(){
        sceneView = self.view as? SCNView
        sceneView.delegate = self
        
        //sceneView.allowsCameraControl = true
        scene = SCNScene(named: scenes[currentScene])
        sceneView.scene = scene
        
        scene.physicsWorld.contactDelegate = self
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        
        tapRecognizer.addTarget(self, action: #selector(GameViewController.sceneViewTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
        
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: joystick)
        if leftPad.frame.intersects(CGRect(x: point?.x ?? 0.0, y: point?.y ?? 0.0, width: 1, height: 1)) {
            leftKnob.center = CGPoint(x: point?.x ?? 0.0, y: point?.y ?? 0.0)
        }
        updateJoystickRotation()
//        if rightPad.frame.intersects(CGRect(x: point?.x ?? 0.0, y: point?.y ?? 0.0, width: 1, height: 1)) {
//            rightKnob.center = CGPoint(x: point?.x ?? 0.0, y: point?.y ?? 0.0)
//            right = true
//        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: joystick)
        if leftPad.frame.intersects(CGRect(x: point?.x ?? 0.0, y: point?.y ?? 0.0, width: 1, height: 1)) {
            leftKnob.center = CGPoint(x: point?.x ?? 0.0, y: point?.y ?? 0.0)
            leftKnob.center = self.leftPad.center
        }
        updateJoystickRotation()
//        if rightPad.frame.intersects(CGRect(x: point?.x ?? 0.0, y: point?.y ?? 0.0, width: 1, height: 1)) {
//            rightKnob.center = CGPoint(x: point?.x ?? 0.0, y: point?.y ?? 0.0)
//            right = false
//        }
        //self.leftKnob.center = self.leftPad.center;
    }
    func pointPair(toBearingDegrees startingPoint: CGPoint, secondPoint endingPoint: CGPoint) -> CGFloat {
        let originPoint = CGPoint(x: endingPoint.x - startingPoint.x, y: endingPoint.y - startingPoint.y) // get origin point to origin by subtracting end from start
        let bearingRadians = atan2f(Float(originPoint.y), Float(originPoint.x)) // get bearing in radians
        var bearingDegrees = bearingRadians * (180.0 / .pi) // convert to degrees
        bearingDegrees = bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees) // correct discontinuity
        return CGFloat(bearingDegrees)
    }
    func setupJoystick(){
//        let rect = CGRect(x: 0, y: 0, width: 200, height: 21)
//                let label = UILabel(frame: rect)
//                label.center = CGPoint(x: 160, y: 284)
//                label.textAlignment = NSTextAlignment.center
//                label.text = "I'm a test label"
                
        joystick = UIImageView()
//        let rightPad = UIImageView()
        leftPad = UIImageView()
//        let rightKnob = UIImageView()
        leftKnob = UIImageView()
        
        joystick.addSubview(leftPad)
        leftPad.addSubview(leftKnob)
        
        joystick.frame = CGRect(x: 0, y: self.view.frame.height - 200, width: self.view.frame.width, height: 200)
        leftPad.frame = CGRect(x: 0, y: 0, width: joystick.frame.width / 2, height: 200)
        leftKnob.frame = CGRect(x: 0, y: 0,width: 50,height: 50)
        
        joystick.backgroundColor = UIColor.clear
        leftKnob.backgroundColor = UIColor.white
        leftPad.backgroundColor = UIColor.clear
        leftPad.layer.cornerRadius = leftPad.frame.width / 2
        leftPad.layer.masksToBounds = true
        leftPad.layer.borderWidth = 5
        leftPad.layer.borderColor = UIColor.white.cgColor
        leftKnob.layer.cornerRadius = leftKnob.frame.width / 2
        leftKnob.layer.masksToBounds = true
        leftKnob.center = leftPad.center
        
        self.view.addSubview(joystick)
    }
    var accelerometer = false
    var mute = false
    @objc func paused(){
        scene.isPaused = true
        let alert = UIAlertController(title: "Paused", message: "The game is paused.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .cancel, handler: { (UIAlertAction) in
            if (self.loadingScene == true){
                return
            }
            self.delayLoadScene(scene: SCNScene(named: self.scenes[self.currentScene]))
            if let splash = self.sounds["splash"] {
                self.ballNode.runAction(SCNAction.playAudio(splash, waitForCompletion: false))
            }
            let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
            explosion.emitterShape = self.ballNode.geometry
            explosion.birthLocation = .surface
            self.ballNode.addParticleSystem(explosion)
            self.scene.isPaused = false
        }))
        if (mute){
            alert.addAction(UIAlertAction(title: "Un-Mute", style: .default, handler: { (UIAlertAction) in
                self.mute = false
                self.setupSounds()
                self.scene.isPaused = false
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Mute", style: .default, handler: { (UIAlertAction) in
                self.mute = true
                self.sounds = [:]
                self.scene.isPaused = false
            }))
        }
        if (accelerometer){
            alert.addAction(UIAlertAction(title: "Joystick", style: .default, handler: { (UIAlertAction) in
                self.accelerometer = false
                self.setupJoystick()
                self.scene.isPaused = false
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Accelerometer", style: .default, handler: { (UIAlertAction) in
                self.accelerometer = true
                self.joystick.removeFromSuperview()
                self.scene.isPaused = false
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Resume", style: .default, handler: { (UIAlertAction) in
            self.scene.isPaused = false
        }))
        self.present(alert, animated: true, completion: nil)
    }
    @objc func jumped(){
        if let jumpSound = sounds["jump"] {
            ballNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
        }
        ballNode.physicsBody?.applyForce(SCNVector3(x: 0, y:4, z: 0), asImpulse: true)
    }
    
    
    
    func setupNodes() {
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)!
        ballNode.physicsBody?.contactTestBitMask = CategoryTree
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)!
        
//        enemyNode = scene.rootNode.childNode(withName: "enemy", recursively: true)
        enemyNodes[0] = scene.rootNode.childNodes(passingTest: { (node, sure) -> Bool in
            node.name == "enemy"
        })
        enemyNodes[1] = scene.rootNode.childNodes(passingTest: { (node, sure) -> Bool in
            node.name == "enemy2"
        })
        enemyNodes[2] = scene.rootNode.childNodes(passingTest: { (node, sure) -> Bool in
            node.name == "enemy3"
        })
        for enemies in enemyNodes {
            for enemy in enemies {
                let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
                explosion.emitterShape = ballNode.geometry
                explosion.birthLocation = .surface
                enemy.addParticleSystem(explosion)
            }
        }
        if (currentScene == 10){
            let backgroundMusic = SCNAudioSource(fileNamed: "background.mp3")!
            backgroundMusic.volume = 0.5
            backgroundMusic.loops = true
            backgroundMusic.load()
    
            let musicPlayer = SCNAudioPlayer(source: backgroundMusic)
            ballNode.addAudioPlayer(musicPlayer)
        }
    }
    
    func setupSounds() {
        let sawSound = SCNAudioSource(fileNamed: "chainsaw.wav")!
        let jumpSound = SCNAudioSource(fileNamed: "jump.wav")!
        let winSound = SCNAudioSource(fileNamed: "win.wav")!
        let splashSound = SCNAudioSource(fileNamed: "splash.wav")!
        sawSound.load()
        jumpSound.load()
        winSound.load()
        splashSound.load()
        sawSound.volume = 0.2
        jumpSound.volume = 0.4
        winSound.volume = 0.6
        splashSound.volume = 1
        
        sounds["saw"] = sawSound
        sounds["jump"] = jumpSound
        sounds["win"] = winSound
        sounds["splash"] = splashSound
        
    }
    
    @objc func sceneViewTapped (recognizer:UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if hitResults.count > 0 {
            let result = hitResults.first
            if let node = result?.node {
                if node.name == "ball" {
                    if let jumpSound = sounds["jump"] {
                        ballNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
                    }
                    ballNode.physicsBody?.applyForce(SCNVector3(x: 0, y:4, z: 0), asImpulse: true)
                }
            }
        }
    }
    
    var joystickRotation:CGFloat? = nil

    func updateJoystickRotation(){
        if leftKnob.center.x != leftPad.center.x && leftKnob.center.y != leftPad.center.y {
            joystickRotation = pointPair(toBearingDegrees: leftPad.center, secondPoint: leftKnob.center) * .pi / 180
        } else {
            joystickRotation = nil
        }
    }
    
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    var loadingScene = false
    func delayLoadScene(scene: SCNScene?){
        if (loadingScene == true){
            return
        }
        loadingScene = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: {
            DispatchQueue.main.async {
                self.loadScene(scene: scene)
            }
        })
    }
    func loadScene(scene: SCNScene?){
        self.scene = nil
        self.sceneView.scene = nil
        self.scene = scene
        self.sceneView.scene = self.scene
        self.scene.physicsWorld.contactDelegate = self
        self.setupNodes()
        self.loadingScene = false
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3,
      rotation: SCNVector4) {
    }

}

extension GameViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let ball = ballNode.presentation
        let ballPosition = ball.position
        
        let targetPosition = SCNVector3(x: ballPosition.x, y: ballPosition.y + 5, z:ballPosition.z + 5)
        var cameraPosition = selfieStickNode.position
        
        let camDamping:Float = 0.3
        
        let xComponent = cameraPosition.x * (1 - camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1 - camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1 - camDamping) + targetPosition.z * camDamping
        
        cameraPosition = SCNVector3(x: xComponent, y: yComponent, z: zComponent)
        selfieStickNode.position = cameraPosition
        
        if (loadingScene == true){
            return
        }
        if (accelerometer == true){
            motion.getAccelerometerData { (x, y, z) in
                self.motionForce = SCNVector3(x: x * 0.05, y:0, z: (y + 0.8) * -0.05)
            }
        } else {
            if let rotation = joystickRotation {
                let x = cos(rotation)
                let z = sin(rotation)
                self.motionForce = SCNVector3(x: Float(x * 0.05), y:self.motionForce.y, z: Float(z * 0.05))
            } else {
                self.motionForce = SCNVector3(0,self.motionForce.y,0)
            }
        }
        ballNode.physicsBody?.velocity += motionForce
        for enemyNode in enemyNodes[0] {
            let enemyPoint = CGPoint(x: CGFloat(enemyNode.presentation.position.x), y: CGFloat(enemyNode.presentation.position.z))
            let ballPoint = CGPoint(x: CGFloat(ballPosition.x), y: CGFloat(ballPosition.z) + 10)
            let enemyRotation = pointPair(toBearingDegrees: enemyPoint, secondPoint: ballPoint) * .pi / 180
            let x = cos(enemyRotation)
            let z = sin(enemyRotation)
            enemyNode.physicsBody?.applyForce(SCNVector3(x: Float(x * 0.05), y:0, z: Float(z * 0.05)), asImpulse: true)
        }
        for enemyNode in enemyNodes[1] {
            let enemyPoint = CGPoint(x: CGFloat(enemyNode.presentation.position.x), y: CGFloat(enemyNode.presentation.position.z))
            let ballPoint = CGPoint(x: CGFloat(ballPosition.x + 10), y: CGFloat(ballPosition.z) + 15)
            let enemyRotation = pointPair(toBearingDegrees: enemyPoint, secondPoint: ballPoint) * .pi / 180
            let x = cos(enemyRotation)
            let z = sin(enemyRotation)
            enemyNode.physicsBody?.applyForce(SCNVector3(x: Float(x * 0.05), y:0, z: Float(z * 0.05)), asImpulse: true)
        }
        for enemyNode in enemyNodes[2] {
            let enemyPoint = CGPoint(x: CGFloat(enemyNode.presentation.position.x), y: CGFloat(enemyNode.presentation.position.z))
            let ballPoint = CGPoint(x: CGFloat(ballPosition.x - 10), y: CGFloat(ballPosition.z) + 15)
            let enemyRotation = pointPair(toBearingDegrees: enemyPoint, secondPoint: ballPoint) * .pi / 180
            let x = cos(enemyRotation)
            let z = sin(enemyRotation)
            enemyNode.physicsBody?.applyForce(SCNVector3(x: Float(x * 0.05), y:0, z: Float(z * 0.05)), asImpulse: true)
        }
        //enemy movement
//        if let enemyNode = enemyNode {
//            
//        }
//        if let enemyNode = enemyNode {
//            if (loadingScene == true){
//                return
//            }
//            self.delayLoadScene(scene: SCNScene(named: scenes[currentScene]))
//            if let splash = sounds["splash"] {
//                ballNode.runAction(SCNAction.playAudio(splash, waitForCompletion: false))
//            }
//            let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
//            explosion.emitterShape = ballNode.geometry
//            explosion.birthLocation = .surface
//            ballNode.addParticleSystem(explosion)
//        }
    }
    
    
}

extension GameViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode:SCNNode!
        
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeB
        }else{
            contactNode = contact.nodeA
        }
        switch contactNode.name {
        case "box":
            break
        case "tree":
            contactNode.isHidden = true
            if let saw = sounds["saw"] {
                ballNode.runAction(SCNAction.playAudio(saw, waitForCompletion: false))
            }
            let waitAction = SCNAction.wait(duration: 15)
            let unhideAction = SCNAction.run { (node) in
                node.isHidden = false
            }

            let actionSequence = SCNAction.sequence([waitAction, unhideAction])

            contactNode.runAction(actionSequence)
            break
        case "goldRing":
            if (loadingScene == true){
                return
            }
            currentScene += 1
            DispatchQueue.main.async {
                if (self.currentScene >= 10){
                    self.score.text = "WIN"
                } else {
                    self.score.text = "\(self.currentScene + 1)/10"
                }
            }
            self.delayLoadScene(scene: SCNScene(named: scenes[currentScene]))
            contactNode.opacity = 0.5
            if let win = sounds["win"] {
                ballNode.runAction(SCNAction.playAudio(win, waitForCompletion: false))
            }
            self.ballNode.addParticleSystem((contactNode.particleSystems?.first)!)
            contactNode.particleSystems?.first?.reset()
            contactNode.removeAllParticleSystems()
            print("WIN")
            break
        case "killbox", "enemy", "enemy2", "enemy3":
            if (loadingScene == true){
                return
            }
            self.delayLoadScene(scene: SCNScene(named: scenes[currentScene]))
            if let splash = sounds["splash"] {
                ballNode.runAction(SCNAction.playAudio(splash, waitForCompletion: false))
            }
            let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
            explosion.emitterShape = ballNode.geometry
            explosion.birthLocation = .surface
            ballNode.addParticleSystem(explosion)
            break
        default:
            print("unknown collision")
            print(contactNode.name)
        }
        
    }
    
    
}

