//
//  ViewController.swift
//  XeroScrollView
//
//  Created by Ratnesh Jain on 10/08/24.
//

import Foundation
import UIKit

class ScrollView: UIView {
    private var displayLink: CADisplayLink!
    private var velocity: CGPoint = .zero
    var decelerationRate: CGFloat = 0.95
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
    }()
    
    private var contentView: UIView = {
        UIView(frame: .zero)
    }()
    
    var contentHeight: CGFloat {
        self.contentView.subviews.reduce(into: 0) { partialResult, view in
            partialResult += view.frame.height
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }
    
    private func configureViews() {
        self.addSubview(contentView)
        self.addGestureRecognizer(panGesture)
    }
    
    func add(_ view: UIView) {
        self.contentView.addSubview(view)
    }
    
    @objc private func panAction(_ gesture: UIPanGestureRecognizer) {
        defer {
            gesture.setTranslation(.zero, in: self)
        }
        let translation = gesture.translation(in: self)
        self.velocity = gesture.velocity(in: self)
        
        var bound = self.bounds
        let newOrigin = bound.origin.y - translation.y
        let minOrigin = CGFloat(0) - self.safeAreaInsets.top
        let maxOrigin = contentHeight - self.bounds.height + self.safeAreaInsets.bottom
        
        bound.origin.y = min(max(minOrigin, newOrigin), maxOrigin)
        
        if gesture.state == .ended || gesture.state == .cancelled {
            startDeceleration()
        }
        
        self.bounds = bound
    }
    
    func startDeceleration() {
        stopDeceleration()
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkAction))
        displayLink.add(to: .main, forMode: .default)
    }
    
    func stopDeceleration() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    @objc private func displayLinkAction() {
        guard let displayLink else { return }
        var bound = self.bounds
        bound.origin.y -= velocity.y * displayLink.duration
        velocity.y *= decelerationRate
        
        let minOrigin = CGFloat(0) - self.safeAreaInsets.top
        let maxOrigin = contentHeight - self.bounds.height + self.safeAreaInsets.bottom
        
        if bound.origin.y < minOrigin {
            bound.origin.y = minOrigin
            stopDeceleration()
        } else if bound.origin.y >= maxOrigin {
            bound.origin.y = maxOrigin
            stopDeceleration()
        }

        self.bounds = bound
        
        if abs(velocity.y) < 0.1 {
            stopDeceleration()
        }
    }
}

class ViewController: UIViewController {
    let scrollView = ScrollView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        self.view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        for i in 1...20 {
            let label = UILabel(frame: .init(x: 0, y: CGFloat(i - 1) * 200, width: self.view.bounds.width, height: 200))
            label.text = "Item \(i)"
            label.textAlignment = .center
            label.backgroundColor = UIColor(hue: CGFloat(i)/20, saturation: 1, brightness: 1, alpha: 1)
            scrollView.add(label)
        }
    }
}

#Preview {
    ViewController()
}
