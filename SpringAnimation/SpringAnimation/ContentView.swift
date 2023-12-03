//
//  ContentView.swift
//  SpringAnimation
//
//  Created by Malith Madhushanka on 2023-12-03.
//

import SwiftUI
import Observation

struct CircleView: View {
    
    var offset: CGPoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.tertiary)
                .frame(width: 50, height: 50)
                .offset(y: -200)
            
            Circle()
                .fill(.tertiary)
                .frame(width: 100, height: 100)
                .offset(y: 200)
            
            Circle()
                .stroke(.primary, lineWidth: 8)
                .frame(width: offset.x, height: offset.x)
                .offset(y: offset.y)
        }
    }
}

// @Animated var offset: Double = 0.0
// var _offset = Animated(wrappedValue: 0.0)
// var offset: Double {
//      get { _offset.wrappedValue }
//      set { _offset.wrappedValue = newValue }
// }

@propertyWrapper
struct Animated<Value: SpringValueProtocol>: DynamicProperty {
    @State var springDouble: SpringValue<Value>
    
    init(wrappedValue: Value) {
        self.springDouble = SpringValue(value: wrappedValue)
    }
    
    var wrappedValue: Value {
        get {
            springDouble.value
        }
        
        nonmutating set {
            springDouble.animate(to: newValue)
        }
    }
    
    var projectedValue: SpringValue<Value> {
        springDouble
    }
}

protocol SpringValueProtocol {
    static func -(lhs: Self, rhs: Self) -> Self
    
    static func +(lhs: Self, rhs: Self) -> Self
    
    static func +=(lhs: inout Self, rhs: Self)
    
    func scaled(by scalar: Double) -> Self
    
    static var zero: Self { get }
    
    var magnitudeSquared: Double { get }
}

extension Double: SpringValueProtocol {
//    static func -(lhs: Double, rhs: Double) -> Double {
//        lhs - rhs
//    }
//    
//    static func +(lhs: Double, rhs: Double) -> Double {
//        lhs + rhs
//    }
//    
//    static func +=(lhs: inout Double, rhs: Double) {
//        lhs += rhs
//    }
    
    func scaled(by scalar: Double) -> Double {
        self * scalar
    }
    
    static public var zero: Double {
        0
    }
}

extension CGPoint: SpringValueProtocol {
    var magnitudeSquared: Double {
        x * x + y * y
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
    
    func scaled(by scalar: Double) -> CGPoint {
        CGPoint(x: self.x * scalar, y: self.y * scalar)
    }
    
    static public var zero: CGPoint {
        CGPoint(x: 0, y: 0)
    }
}

@Observable
class SpringValue<Value: SpringValueProtocol>: AnimatedProtocol {
    var isDone: Bool {
        let displacement = value - target
        return velocity.magnitudeSquared < epsilon && displacement.magnitudeSquared < epsilon
    }
    
    let id = UUID()
    var value: Value
    var target: Value
    var velocity: Value = .zero
    
    let epsilon = 0.0005
    
    init(value: Value) {
        self.value = value
        self.target = value
    }
    
    func animate(to: Value) {
        AnimatonManager.shared.addAnimation(self)
        target = to
    }
    
    // from swift
    let stiffness: Double = Spring().stiffness
    let damping: Double = Spring().damping
    
    func update(timeDelta: Double) {
        let displacement = value - target
        // HOOKS LAW
        let springForce = displacement.scaled(by: -stiffness)
        let dampingForce = velocity.scaled(by: -damping)
        let combinedForce = springForce + dampingForce
        // a = F/m
        let acceleration = combinedForce
        velocity += acceleration.scaled(by: timeDelta)
        value += velocity.scaled(by: timeDelta)
    }
}

protocol AnimatedProtocol {
    var id: UUID { get }
    var isDone: Bool { get }
    func update(timeDelta: TimeInterval)
}

@Observable
class AnimatonManager {
    
    static let shared = AnimatonManager()
    var animations: [UUID:AnimatedProtocol] = [:]
    
    func addAnimation(_ animation: AnimatedProtocol) {
        print("ADDING ANIMATION: \(animation.id)")
        animations[animation.id] = animation
    }
    
    func step(timeDelta: TimeInterval) {
        for animation in animations.values {
            animation.update(timeDelta: timeDelta)
            print("STEPPING ANIMATION: \(animation.id): \(timeDelta)")
            if animation.isDone {
                print("IS DONE ANIMATION: \(animation.id)")
                animations.removeValue(forKey: animation.id)
            }
        }
    }
}

struct AnimationManagerModifier: ViewModifier {
    @State var manager = AnimatonManager.shared
    
    @State var lastRenderedDate: Date?
    
    func body(content: Content) -> some View {
        content
            .background {
                TimelineView(.animation(paused: manager.animations.isEmpty)) { context in
                    Color.clear
                        .onChange(of: context.date) {
                            let timeDelta = context.date.timeIntervalSince(lastRenderedDate ?? Date())
                            lastRenderedDate = context.date
                            manager.step(timeDelta: timeDelta)
                        }
                }
            }
            .onChange(of: manager.animations.isEmpty) {
                if $1 {
                    lastRenderedDate = nil
                }
            }
    }
}

struct ContentView: View {
    @State var offset: CGPoint = CGPoint(x: 100, y: 200)
    @Animated var offsetSpring: CGPoint = CGPoint(x: 100, y: 200)
    // @animated var offsetSpring = 200.0
    
    @State var lastDate: Date = Date()
    @State var timeDelta: Double = 0.0
    
    @State var isBig: Bool = true
    
    var body: some View {
        HStack(spacing: 40) {
            CircleView(offset: offset)
                .animation(.spring, value: offset)
            
            CircleView(offset: offsetSpring)
        }
        .onTapGesture {
            if isBig {
                offset = CGPoint(x: 50, y: -200)
            } else {
                offset = CGPoint(x: 100, y: 200)
            }
            offsetSpring = offset
            isBig.toggle()
        }
        .modifier(AnimationManagerModifier())
    }
}

#Preview {
    ContentView()
}
