//
//  ContainerViewController.swift
//  SlideOutNavigation
//
//  Created by James Frost on 03/08/2014.
//  Copyright (c) 2014 James Frost. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case collapsed
    case leftPanelExpanded
}

class ContainerViewController: UIViewController, CenterViewControllerDelegate, UIGestureRecognizerDelegate {
    fileprivate var centerNavigationController: UINavigationController!
    fileprivate var centerViewController: TrafficViewController!
    
    fileprivate var currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadow = currentState != .collapsed
            showShadowForCenterViewController(shouldShowShadow)
            centerViewController.view.isUserInteractionEnabled = currentState == .collapsed
        }
    }
    
    fileprivate var leftViewController: SortOptionsTableViewController?
    
    fileprivate let centerPanelExpandedOffset: CGFloat = 150
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centerViewController = UIStoryboard.centerViewController()
        centerViewController.delegate = self
        
        centerNavigationController = UINavigationController(rootViewController: centerViewController)
        view.addSubview(centerNavigationController.view)
        addChildViewController(centerNavigationController)
        
        centerNavigationController.didMove(toParentViewController: self)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    func collapseSidePanel() {
        toggleLeftPanel()
    }
    
    
    // MARK: - CenterViewController delegate methods
    
    func toggleLeftPanel() {
        let notAlreadyExpand = (currentState != .leftPanelExpanded)
        
        if notAlreadyExpand {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpand)
    }
    
    func addLeftPanelViewController() {
        if leftViewController == nil {
            leftViewController = UIStoryboard.leftViewController()
            
            addChildSidePanelController(leftViewController!)
        }
    }
    
    func animateLeftPanel(shouldExpand: Bool) {
        if shouldExpand {
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerNavigationController.view.frame.width -
                centerPanelExpandedOffset)
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { [weak self]
                _ in
                self?.currentState = .collapsed
                
                self?.leftViewController?.view.removeFromSuperview()
                self?.leftViewController = nil
            }
        }
    }
    
    func addChildSidePanelController(_ sidePanelController: SortOptionsTableViewController) {
        sidePanelController.delegate = centerViewController
        
        view.insertSubview(sidePanelController.view, at: 0)
        
        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
                self.centerNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
    func showShadowForCenterViewController(_ shouldShowShadow: Bool) {
        if shouldShowShadow {
            centerNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            centerNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
    // MARK: Gesture recognizer
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let _ = centerNavigationController.topViewController as? TrafficViewController else {
            return
        }
        
        let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
        
        switch recognizer.state {
        case .began:
            if currentState == .collapsed {
                if gestureIsDraggingFromLeftToRight {
                    addLeftPanelViewController()
                }
                showShadowForCenterViewController(true)
            }
            
        case .changed:
            // No back movement
            if leftViewController != nil && recognizer.view!.frame.origin.x >= 0 {
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
            }
            
            recognizer.setTranslation(CGPoint.zero, in: view)
            
        case .ended:
            // Animate the side panel open or closed if view is halfway in
            if leftViewController != nil {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
            
        default:
            break
        }
    }
}

private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
    
    class func leftViewController() -> SortOptionsTableViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "SortOptionsTableViewController") as? SortOptionsTableViewController
    }
    
    class func centerViewController() -> TrafficViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "TrafficViewController") as? TrafficViewController
    }
}
