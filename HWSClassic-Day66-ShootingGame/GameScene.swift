//
//  GameScene.swift
//  Project18M
//
//  Created by Romain Buewaert on 02/11/2021.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var newPartyLabel: SKLabelNode!
    var bestScoreLabel: SKLabelNode!
    var bestScore = 0
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var numberOfBallLabel: SKLabelNode!
    var numberOfBall = 5 {
        didSet {
            numberOfBallLabel.text = "Number of ball : \(numberOfBall)"
        }
    }
    var countdownLabel: SKLabelNode!
    var countdwonTimer: Timer?
    var countdown = 60 {
        didSet {
            countdownLabel.text = "Time remaining: \(countdown)"
        }
    }
    var gameTimer: Timer?
    let targets = ["bird", "plane", "missile"]
    var ballIsInGame = false

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)

        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.fontSize = 36
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: 20)
        addChild(scoreLabel)

        bestScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        bestScoreLabel.fontSize = 36
        bestScoreLabel.fontColor = .black
        bestScoreLabel.text = "Best Score: \(bestScore)"
        bestScoreLabel.horizontalAlignmentMode = .left
        bestScoreLabel.position = CGPoint(x: 20, y: 720)
        addChild(bestScoreLabel)

        countdownLabel = SKLabelNode(fontNamed: "Chalkduster")
        countdownLabel.fontSize = 36
        countdownLabel.fontColor = .black
        countdownLabel.text = "Time remaining: \(countdown)"
        countdownLabel.horizontalAlignmentMode = .left
        countdownLabel.position = CGPoint(x: 20, y: 680)
        addChild(countdownLabel)

        numberOfBallLabel = SKLabelNode(fontNamed: "Chalkduster")
        numberOfBallLabel.fontSize = 36
        numberOfBallLabel.horizontalAlignmentMode = .right
        numberOfBallLabel.position = CGPoint(x: 1000, y: 20)
        addChild(numberOfBallLabel)

        score = 0
        numberOfBall = 5
        countdown = 60
        ballIsInGame = false

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        gameTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(createAllTargets), userInfo: nil, repeats: true)
        countdwonTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(changeTimeremaining), userInfo: nil, repeats: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if ballIsInGame == false && numberOfBall > 0 {
            let ball = SKSpriteNode(imageNamed: "ball")
            ball.position = CGPoint(x: location.x, y: 20)
            ball.name = "ball"
            ball.xScale = 0.4
            ball.yScale = 0.4
            ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
            ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0
            ball.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
            addChild(ball)
            run(SKAction.playSoundFileNamed("ballSound.wav", waitForCompletion: false))
            ballIsInGame = true
        }

        if newPartyLabel != nil {
            let objects = nodes(at: location)
            if objects.contains(newPartyLabel) {
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .fill
                    scene.bestScore = bestScore
                    let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                    view?.presentScene(scene, transition: transition)
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if node.position.x < -300 || node.position.x > 1400 {
                node.removeFromParent()
            } else if node.position.y > 1000 {
                node.removeFromParent()
                ballIsInGame = false
                numberOfBall -= 1
                score -= 1
                if numberOfBall == 0 {
                    gameOver()
                }
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA.name == "ball" {
            collision(between: nodeA, object: nodeB)
        } else if nodeB.name == "ball" {
            collision(between: nodeB, object: nodeA)
        }
    }

    func createTarget(xVelocity: Int, xPosition: Int, yPosition: Int) {
        guard let randomTarget = targets.randomElement() else { return }
        let scales = [1.5, 2, 3]
        guard let scale = scales.randomElement() else { return }

        let target = SKSpriteNode(imageNamed: randomTarget)
        target.position = CGPoint(x: xPosition, y: yPosition)
        target.xScale = CGFloat(scale)
        target.yScale = CGFloat(scale)
        target.name = randomTarget
        target.physicsBody = SKPhysicsBody(texture: target.texture!, size: target.size)
        target.physicsBody?.categoryBitMask = 1
        target.physicsBody?.velocity = CGVector(dx: xVelocity, dy: 0)
        target.physicsBody?.linearDamping = 0
        target.physicsBody?.angularDamping = 0

        addChild(target)
    }

    @objc func createAllTargets() {
        createTarget(xVelocity: -150, xPosition: 1000, yPosition: 650)
        createTarget(xVelocity: 200, xPosition: 20, yPosition: 450)
        createTarget(xVelocity: -300, xPosition: 1000, yPosition: 250)
    }

    @objc func changeTimeremaining() {
        countdown -= 1
        if countdown == 0 {
            gameOver()
        }
    }

    func collision(between ball: SKNode, object: SKNode) {
        ballIsInGame = false
        destroy(ball: ball, object: object)
        if object.name == "bird" {
            score -= 5
            numberOfBall -= 1
            if numberOfBall == 0 {
                gameOver()
            }
            run(SKAction.playSoundFileNamed("birdSound.wav", waitForCompletion: false))
        } else if object.name == "plane" || object.name == "missile" {
            if object.xScale == 1.5 {
                score += 10
            } else if object.xScale == 2 {
                score += 5
            } else {
                score += 3
            }
            run(SKAction.playSoundFileNamed("explosionSound.wav", waitForCompletion: false))
        }
    }

    func destroy(ball: SKNode, object: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "explosion") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        ball.removeFromParent()
        object.removeFromParent()
    }

    func gameOver() {
        let gameOver = SKLabelNode(fontNamed: "Chalkduster")
        gameOver.text = "GAME OVER"
        gameOver.fontSize = 70
        gameOver.fontColor = .red
        gameOver.zPosition = 1
        gameOver.horizontalAlignmentMode = .center
        gameOver.position = CGPoint(x: 512, y: 500)
        addChild(gameOver)

        let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Final Score: \(score)"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = .red
        scoreLabel.zPosition = 1
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 512, y: 400)
        addChild(scoreLabel)

        newPartyLabel = SKLabelNode(fontNamed: "Chalkduster")
        newPartyLabel.text = "Click Here To another Party"
        newPartyLabel.fontSize = 50
        newPartyLabel.fontColor = .red
        newPartyLabel.zPosition = 1
        newPartyLabel.horizontalAlignmentMode = .center
        newPartyLabel.position = CGPoint(x: 512, y: 300)
        addChild(newPartyLabel)

        if score > bestScore {
            bestScore = score
            bestScoreLabel.text = "Best Score: \(bestScore)"
        }

        gameTimer?.invalidate()
        countdwonTimer?.invalidate()
    }
}
