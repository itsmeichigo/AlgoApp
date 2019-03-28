//
//  ConfettiView.swift
//  Pods
//
//  Created by Sudeep Agarwal on 12/14/15.
//
//

import UIKit
import QuartzCore

public class ConfettiView: UIView {

    public enum ConfettiType {
        case confetti
        case triangle
        case star
        case diamond
        case image(UIImage)
        case mixed
    }

    public var colors: [UIColor] = [
        UIColor(red:0.30, green:0.76, blue:0.85, alpha:1.0),
        UIColor(red:0.58, green:0.39, blue:0.55, alpha:1.0),
        UIColor(red:0.95, green:0.40, blue:0.27, alpha:1.0),
        UIColor(red:1.00, green:0.78, blue:0.36, alpha:1.0),
        UIColor(red:0.48, green:0.78, blue:0.64, alpha:1.0)
    ]
    public var intensity: Float = 0.5
    public var type: ConfettiType = .confetti
    
    public var isActive: Bool {
        return active
    }
    
    private var active: Bool = false
    private var emitter: CAEmitterLayer!

    public func startConfetti() {
        emitter = CAEmitterLayer()

        emitter.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: 0)
        emitter.emitterShape = CAEmitterLayerEmitterShape.line
        emitter.emitterSize = CGSize(width: frame.size.width, height: 1)

        var cells = [CAEmitterCell]()
        if case ConfettiType.mixed = type,
            let confettiImage = cellImage(for: .confetti),
            let triangleImage = cellImage(for: .triangle),
            let starImage = cellImage(for: .star),
            let diamondImage = cellImage(for: .diamond) {
            
            let images = [confettiImage, triangleImage, starImage, diamondImage]
            for (index, image) in images.enumerated() {
                cells.append(confettiCell(with: colors[index], image: image))
            }
            
        } else if let image = cellImage(for: type) {
            for color in colors {
                cells.append(confettiCell(with: color, image: image))
            }
        }
        

        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        active = true
    }

    public func stopConfetti() {
        emitter?.birthRate = 0
        active = false
    }

    private func cellImage(for type: ConfettiType) -> UIImage? {

        var fileName: String!

        switch type {
        case .confetti:
            fileName = "confetti"
        case .triangle:
            fileName = "triangle"
        case .star:
            fileName = "star"
        case .diamond:
            fileName = "diamond"
        case let .image(customImage):
            return customImage
        default:
            return nil
        }

        return UIImage(named: fileName)
    }

    private func confettiCell(with color: UIColor, image: UIImage) -> CAEmitterCell {
        let confetti = CAEmitterCell()
        confetti.birthRate = 6.0 * intensity
        confetti.lifetime = 14.0 * intensity
        confetti.lifetimeRange = 0
        confetti.color = color.cgColor
        confetti.velocity = CGFloat(350.0 * intensity)
        confetti.velocityRange = CGFloat(80.0 * intensity)
        confetti.emissionLongitude = CGFloat(Double.pi)
        confetti.emissionRange = CGFloat(Double.pi)
        confetti.spin = CGFloat(3.5 * intensity)
        confetti.spinRange = CGFloat(4.0 * intensity)
        confetti.scaleRange = CGFloat(intensity)
        confetti.scaleSpeed = CGFloat(-0.1 * intensity)
        confetti.contents = image.cgImage
        
        return confetti
    }
}
