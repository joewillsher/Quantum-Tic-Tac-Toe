//
//  ViewController.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 08/03/2015.
//  Copyright (c) 2015 Josef Willsher. All rights reserved.
//

import UIKit
import Model
import GameplayKit

/// Token describing the current user activity and holding the callblack function to the model
private enum InputToken {
    case turn(callback: (BoardPosition, BoardPosition) -> Void)
    case select(between: (BoardPosition, BoardPosition), callback: (BoardPosition) -> Void)
}

/// Delegate which manages the quantum tiles
private protocol SelectionStackDelegate {
    var views: [[UITextView]] { get set }
    var model: GameModel { get }
    
    func addQuantumTile(at: BoardPosition)
    func removeLastQuantumTile(at: BoardPosition)
}

/// Stack which manages users tapping the quantum tiles
private struct SelectionStack {
    var stack = [BoardPosition]()
    var delegate: SelectionStackDelegate?
    
    mutating func toggleStack(_ pos: BoardPosition, add: Bool = true) {
        
        for (index, item) in stack.enumerated() where item.0 == pos.0 && item.1 == pos.1{ // if contains pos
            stack.remove(at: index)
            delegate?.removeLastQuantumTile(at: pos)
            return
        }
        
        if add { delegate?.addQuantumTile(at: pos) }
        stack.append(pos)
    }
    
    mutating func reset() {
        stack = [BoardPosition]()
    }
}

extension UIView {
    func removeGestureRecognisers() {
        for g in gestureRecognizers ?? [] { removeGestureRecognizer(g) }
    }
}


class GameViewController: UIViewController, SelectionStackDelegate {
    
    @IBOutlet weak var b0: UIView!
    @IBOutlet weak var b1: UIView!
    @IBOutlet weak var b2: UIView!
    @IBOutlet weak var b3: UIView!
    @IBOutlet weak var b4: UIView!
    @IBOutlet weak var b5: UIView!
    @IBOutlet weak var b6: UIView!
    @IBOutlet weak var b7: UIView!
    @IBOutlet weak var b8: UIView!
    
    @IBOutlet weak var containerView: UIView! { didSet { containerView.layer.cornerRadius = 5 }}
    @IBOutlet weak var currentPlayerView: CurrentPlayerView! { didSet { currentPlayerView.setup() }}
    
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var redScore: UILabel!
    @IBOutlet weak var blackScore: UILabel!

    fileprivate var model = GameModel()
    
    fileprivate var inputToken: InputToken?
    fileprivate var selectionStack = SelectionStack()
    fileprivate var player: QuantumPlayer?
    
    fileprivate var strategist = GKMinmaxStrategist()
    fileprivate var AIModel = ModelClass()
    
    var AIEnabled = false
    fileprivate var AIPlayer: Player = (arc4random() % 2 == 0) ? .o : .x
    fileprivate var isAITurn: Bool { return model.player == AIPlayer && AIEnabled }
    
    fileprivate var scores: [Player: Double] = [.x: 0.0, .o: 0.0]
    
    fileprivate let calculationQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    
    fileprivate let animationScale: CGFloat = 1.2
    fileprivate let initialScale: CGFloat = 0.6
    fileprivate let animationDuration: Double = 0.2
    fileprivate let initialAnimationDuration: Double = 0.1
    
    fileprivate var menu: UIButton!
    fileprivate var again: UIButton!
    fileprivate var desc: UILabel!

    fileprivate func resetStack() {
        selectionStack.reset()
        inputToken = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreView.alpha = 0
        
        selectionStack.delegate = self
        model.delegate = self
        
        AIModel.gameModel = model
        strategist.gameModel = AIModel
        strategist.randomSource = GKARC4RandomSource()
        
        redScore.textColor = UIColor.myRed()
        
        #if DEBUG
            strategist.maxLookAheadDepth = 2
        #else
            strategist.maxLookAheadDepth = 5
        #endif
        
        for b in containerView.subviews {
            let tap = UITapGestureRecognizer(target: self, action: #selector(GameViewController.tapped(_:)))
            b.addGestureRecognizer(tap)
            b.layer.cornerRadius = 7
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        model.beginTurn()
    }
    
    fileprivate func bestStrategy() {
        
        containerView.isUserInteractionEnabled = false
        currentPlayerView.displayAICalculating(for: model.player)
        
        calculationQueue.async {
        
            let start = CFAbsoluteTimeGetCurrent()
            
            guard let p = self.AIModel.players?[self.model.player.index], let update = self.strategist.bestMove(for: p) else { return }
            
            let delay = CFAbsoluteTimeGetCurrent() - start
            Thread.sleep(forTimeInterval: delay < 0.4 ? 0.4-delay : 0)
            
            DispatchQueue.main.async {
                
                switch (update as? ClassicalMoveClass, update as? QuantumMoveClass) {
                case (let a?, _):
                    print("Best: classical piece:\(a.piece) pos:\(a.position)")
                    guard let d = self.AIModel.gameModel.lastPieces else { break }
                    
                    let pos = self.AIModel.gameModel.gameBoard.locations(of: d.0)
                    self.animateDownBoxes((pos[0], pos[1]))
                    
                case (_, let a?):
                    print("Best: quantum pos1:\(a.positions.0) pos2:\(a.positions.1)")
                    self.addQuantumTile(at: a.positions.0)
                    self.addQuantumTile(at: a.positions.1)
                    
                default:
                    break
                }
                
                self.containerView.isUserInteractionEnabled = true
                self.currentPlayerView.endAICalculating()
                
                self.AIModel.apply(update)
            }
            
        }
    }
    
    /// Manages all tap gestures
    func tapped(_ gesture: UITapGestureRecognizer) {
        guard let s = gesture.view?.restorationIdentifier, let i = Int(s), case let pos = (i%3, i/3) else { return }
        if case let .select(between, _)? = inputToken, !(areEqual(pos, between.0) || areEqual(pos, between.1)) { return }
        
        if case .select? = inputToken {
            selectionStack.toggleStack(pos, add: false)
        } else {
            selectionStack.toggleStack(pos)
        }
        
        if case let .turn(callback)? = inputToken, let f = selectionStack.stack.first, let l = selectionStack.stack.last, selectionStack.stack.count == 2 {
            
            resetStack()
            callback(f,l)
            
        } else if case let .select(items, callback)? = inputToken, let item = selectionStack.stack.last, areEqual(items.0, item) || areEqual(items.1, item) {

            animateDownBoxes(items)
            resetStack()
            callback(item)
            
        }
    }
    
    fileprivate func animateDownBoxes(_ items: (BoardPosition, BoardPosition)) {
        
        let (v1, v2) = (button(for: items.0), button(for: items.1))
        for b in [b0,b1,b2,b3,b4,b5,b6,b7,b8] {
            if b === v1 || b === v2 {
                UIView.animate(withDuration: 0.2, animations: { b?.transform = CGAffineTransform(scaleX: 1, y: 1) }) 
            } else {
                UIView.animate(withDuration: 0.2, animations: { b?.alpha = 1 }) 
            }
        }
        
    }
    
    
    /// Updates UI to make tile classical
    func makeTile(at position: BoardPosition, classicalPlayer player: Player) {
        let v = button(for: position)
        
        let tv = UITextView(frame: CGRect(origin: CGPoint(x: 10, y: 0), size: CGSize(width: v.frame.size.width - 20, height: v.frame.size.height - 25)))
        tv.text = player == .x ? "X" : "O"
        tv.textAlignment = .center
        tv.font = UIFont.systemFont(ofSize: tv.frame.height-6, weight: 9)
        tv.backgroundColor = UIColor.clear
        tv.isUserInteractionEnabled = false
        tv.textColor = UIColor.white
        
        for view in v.subviews {
            UIView.animate(withDuration: animationDuration/5,
                animations: { view.alpha = 0 },
                completion: { _ in view.removeFromSuperview()})
        }
        tv.alpha = 0
        v.addSubview(tv)
        UIView.animate(withDuration: animationDuration, animations: {
            tv.alpha = 1
            v.backgroundColor = player == .x ? UIColor.black : UIColor.myRed()
        }) 
        
        v.removeGestureRecognisers()
    }
    
    /// Array of pointers to the UIViews to be added into the board
    fileprivate var views: [[UITextView]] = [[],[],[],[],[],[],[],[],[]]
    
    /// Updates the UI to add a quantum tile at position
    func addQuantumTile(at position: BoardPosition) {
        let v = button(for: position)
        let i = position.1*3 + position.0
        let n = views[i].count, x = (CGFloat(n%3))*(v.frame.size.width/3), y = (CGFloat(n/3))*(v.frame.size.height/3)
        
        let sv = UITextView(frame: CGRect(x: x, y: y, width: v.frame.size.width/3, height: v.frame.size.height/3))
        sv.backgroundColor = player?.0 == .x ? UIColor.black : UIColor.myRed()
        sv.layer.cornerRadius = 5
        sv.isUserInteractionEnabled = false
        
        if let player = player {
            let attString = NSMutableAttributedString(string: (player.0 == .x ? "X" : "O") + "\(player.1)" )
            
            attString.addAttributes([
                NSFontAttributeName as String: UIFont.systemFont(ofSize: sv.frame.height/2, weight: 4),
                NSForegroundColorAttributeName: UIColor.white
                ], range: NSRange(location: 0, length: "\(player.1)".characters.count+1))
            
            attString.addAttributes([
                NSBaselineOffsetAttributeName as String: NSNumber(value: -6 as Float),
                NSFontAttributeName as String: UIFont.systemFont(ofSize: sv.frame.height/4, weight: 2)
                ], range: NSRange(location: 1, length: "\(player.1)".characters.count))
            
            sv.attributedText = attString
            sv.textAlignment = .center
        }
        views[i].append(sv)
        
        sv.alpha = 0.4
        sv.transform = CGAffineTransform(scaleX: initialScale, y: initialScale)
        v.addSubview(sv)
        
        UIView.animate(withDuration: initialAnimationDuration, animations: {
            sv.alpha = 1
            sv.transform = CGAffineTransform(scaleX: 1, y: 1)
        }) 
    }
    
    /// Updates the UI to remove the last quantum tile at position
    func removeLastQuantumTile(at position: BoardPosition) {
        let i = position.1*3 + position.0
        let sv = views[i].removeLast()
        
        UIView.animate(withDuration: initialAnimationDuration,
            animations: {
                sv.alpha = 0.4
                sv.transform = CGAffineTransform(scaleX: self.initialScale, y: self.initialScale)
            }, completion: { _ in sv.removeFromSuperview() })
    }
    
    /// Upates UI to request selection between 2 tiles
    func requestSelection(between p: (BoardPosition, BoardPosition)) {
        let v1 = button(for: p.0), v2 = button(for: p.1)
        
        for b in containerView.subviews {
            if b === v1 || b === v2 {
                
                b.isUserInteractionEnabled = false
                UIView.animate(withDuration: animationDuration,
                    delay: 0,
                    usingSpringWithDamping: 0.05,
                    initialSpringVelocity: 1,
                    options: .curveLinear,
                    animations: {
                        
                        let c = CGSize(width: self.containerView.frame.width / 2, height: self.containerView.frame.size.height / 2)
                        let o = CGSize(width: b.center.x - c.width, height: b.center.y - c.height)
                        
                        let scale = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
                        let transform = CGAffineTransform(translationX: o.width * 0.1, y: o.height * 0.1)
                        
                        b.transform = scale.concatenating(transform)
                        
                    }, completion: { _ in
                        b.isUserInteractionEnabled = true
                })
            } else {
                UIView.animate(withDuration: animationDuration) { b.alpha = 0.4 }
            }
        }
        
    }
    
    fileprivate func button(for pos: BoardPosition) -> UIView {
        return [[b0,b1,b2],[b3,b4,b5],[b6,b7,b8]][pos.1][pos.0]
    }
    
    fileprivate func presentConsole(winner: Player?) {
        
        let menu = UIButton(frame: CGRect(x: 0, y: -70, width: view.frame.width/3, height: 70))
        let desc = UILabel(frame: CGRect(x: view.frame.width/3, y: -70, width: view.frame.width/3, height: 70))
        let again = UIButton(frame: CGRect(x: 2*view.frame.width/3, y: -70, width: view.frame.width/3, height: 70))
        
        menu.setTitle("Back", for: UIControlState())
        again.setTitle("Play again", for: UIControlState())
        menu.setTitleColor(UIColor.white, for: UIControlState())
        again.setTitleColor(UIColor.white, for: UIControlState())
        
        desc.textColor = UIColor.white
        desc.textAlignment = .center
        desc.font = UIFont.systemFont(ofSize: 22, weight: 7)
        
        if let winner = winner {
            if AIEnabled {
                if AIPlayer == winner {
                    desc.text = "You Lost"
                } else {
                    desc.text = "You Won"
                }
            } else {
                if winner == .x {
                    desc.text = "X Won"
                } else {
                    desc.text = "O Won"
                }
            }
        } else {
            desc.text = "You Drew"
        }
        
        view.addSubview(menu)
        view.addSubview(desc)
        view.addSubview(again)

        menu.addTarget(self, action: #selector(GameViewController.menuPress), for: .touchUpInside)
        again.addTarget(self, action: #selector(GameViewController.againPress), for: .touchUpInside)
        
        UIView.animate(withDuration: animationDuration*2.5,
            delay: 0.6,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                menu.frame.origin.y = 0
            },
            completion: nil)
        UIView.animate(withDuration: animationDuration*2.5,
            delay: 0.6+animationDuration*0.6,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                desc.frame.origin.y = 0
            },
            completion: nil)
        UIView.animate(withDuration: animationDuration*2.5,
            delay: 0.6+animationDuration*1.2,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                again.frame.origin.y = 0
            },
            completion: nil)
        
        
        UIView.animate(withDuration: 0.01, delay: 0.6, options: [], animations: {
            self.scoreView.transform = CGAffineTransform(scaleX: self.initialScale, y: self.initialScale)
            self.scoreView.alpha = 0.4
            }, completion: { _ in
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.scoreView.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.scoreView.alpha = 1
                }) 
        })
        
        self.menu = menu
        self.again = again
        self.desc = desc
    }
    
    func menuPress() {
        dismiss(animated: true, completion: nil)
    }
    
    func againPress() {
        model = GameModel()
        AIModel = ModelClass()
        
        containerView.clipsToBounds = false
        views = [[],[],[],[],[],[],[],[],[]]
        
        self.viewDidLoad()
        self.viewDidAppear(false)
        
        UIView.animate(withDuration: animationDuration*2,
            animations: {
                self.menu.frame.origin.y = -70
                self.again.frame.origin.y = -70
                self.desc.frame.origin.y = -70
                
                self.view.backgroundColor = UIColor.white

                for layer in self.containerView.layer.sublayers ?? [] where layer is LineLayer {
                    layer.removeFromSuperlayer()
                }
                
                for view in self.containerView.subviews {
                    for sub in view.subviews {
                        sub.removeFromSuperview()
                    }
                    view.backgroundColor = UIColor.lightGray
                }
                
                self.scoreView.alpha = 0
                
                self.currentPlayerView.alpha = 1
                self.currentPlayerView.transform = CGAffineTransform(scaleX: 1, y: 1)
            },
            completion: { _ in
                self.menu.removeFromSuperview()
                self.again.removeFromSuperview()
                self.desc.removeFromSuperview()
        })
        
    }
    
    fileprivate func gameOver() {
        for b in containerView.subviews { b.removeGestureRecognisers() }
        
        currentPlayerView.backgroundColor = UIColor.clear
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
//        redScore.text = formatter.string(from: NSNumber(scores[.o]!))
//        blackScore.text = formatter.string(from: NSNumber(scores[.x]!))
        
        UIView.animate(withDuration: animationDuration,
            animations: {
                self.currentPlayerView.alpha = 0.4
                self.currentPlayerView.transform = CGAffineTransform(scaleX: self.initialScale, y: self.initialScale)
                self.view.backgroundColor = UIColor(white: 0.55, alpha: 1)
                
            }, completion: { _ in
                self.currentPlayerView.alpha = 0
        })
        
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact {
            return UIInterfaceOrientationMask.portrait
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    
}

class LineLayer: CAShapeLayer {
}

// All below functions are called by the model, to update the UI
extension GameViewController: GameModelProtocol {
    
    func requestSelection(between t: (BoardPosition, BoardPosition), player: Player, completion: @escaping (BoardPosition) -> Void) {
        self.player = nil
        inputToken = .select(between: t, callback: completion)
        
        if isAITurn { bestStrategy() }
        else { currentPlayerView.displaySelectTile(for: player) }
    }
    
    func addQuantumPieces(for player: QuantumPlayer, completion: @escaping (BoardPosition, BoardPosition) -> Void) {
        self.player = player
        inputToken = .turn(callback: completion)
        
        if isAITurn { bestStrategy() }
        else { currentPlayerView.displayAddQuantum(for: player) }
    }
    
    func drawWin(at loc: BoardStrip) {
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            Thread.sleep(forTimeInterval: self.animationDuration)
            
            DispatchQueue.main.async {
                let start: (x: CGFloat, y: CGFloat)
                let end: (x: CGFloat, y: CGFloat)
                
                switch loc {
                case let .row(r):
                    let y = CGFloat(r)*16 + self.b0.frame.height*(CGFloat(r)+0.5)
                    start = (0, y)
                    end = (self.containerView.frame.width, y)
                    
                case let .column(c):
                    let x = CGFloat(c)*16 + self.b0.frame.width*(CGFloat(c)+0.5)
                    start = (x, 0)
                    end = (x, self.containerView.frame.height)
                    
                case let .diagonal(d) where d == .tl:
                    start = (0,0)
                    end = (self.containerView.frame.width, self.containerView.frame.height)
                    
                case let .diagonal(d) where d == .tr:
                    start = (self.containerView.frame.width,0)
                    end = (0, self.containerView.frame.height)
                    
                default: return
                }
                
                self.containerView.clipsToBounds = true
                
                let path = CGMutablePath()
                path.move(to: CGPoint(x: start.x, y: start.y), transform: .identity)
                path.addLine(to: CGPoint(x: end.x, y: end.y), transform: .identity)
                
                let shapeLayer = LineLayer()
                shapeLayer.path = path
                shapeLayer.strokeColor = UIColor(red: 50/255, green: 0/255, blue: 190/255, alpha: 1).cgColor
                shapeLayer.lineWidth = 8
                self.containerView.layer.addSublayer(shapeLayer)
                
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0
                animation.toValue = 1
                animation.duration = self.animationDuration
                shapeLayer.add(animation, forKey: nil)
            }
        }
        
    }
    
    func presentWin(for winner: WinType) {
        
        switch winner {
        case .win(let winner):
            presentConsole(winner: winner)
                
            if let s = scores[winner] {
                scores[winner] = s+1
            }
            
        case .doubleWin(let winner):
            presentConsole(winner: winner)
            
            if let s = scores[winner] {
                scores[winner] = s+1.5
            }
            
        case .narrowWin(let winner):
            presentConsole(winner: winner)
            
            if let s = scores[winner] {
                scores[winner] = s+0.5
            }

        case .draw:
            presentConsole(winner: nil)
            
        }
        
        gameOver()

    }
}


extension UIColor {
    
    static func myRed() -> UIColor {
        return UIColor(red: 1, green: 0.1, blue: 0.05, alpha: 1)
    }
    
}

