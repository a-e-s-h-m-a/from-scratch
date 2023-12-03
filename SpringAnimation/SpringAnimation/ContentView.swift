//
//  ContentView.swift
//  SpringAnimation
//
//  Created by Malith Madhushanka on 2023-12-03.
//

import SwiftUI
import Observation

struct CircleView: View {
    
    var offset: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.tertiary)
                .frame(width: 100, height: 100)
                .offset(y: -200)
            
            Circle()
                .fill(.tertiary)
                .frame(width: 100, height: 100)
                .offset(y: 200)
            
            Circle()
                .stroke(.primary, lineWidth: 8)
                .frame(width: 100, height: 100)
                .offset(y: offset)
        }
    }
}

@Observable
class SpringDouble {
    var value: Double
    var target: Double
    var velocity: Double = 0
    
    init(value: Double) {
        self.value = value
        self.target = value
    }
    
    func animate(to: Double) {
        target = to
    }
    
    // from swift
    let stiffness: Double = Spring().stiffness
    let damping: Double = Spring().damping
    
    func update(timeDelta: Double) {
        let displacement = value - target
        // HOOKS LAW
        let springForce = -displacement * stiffness
        let dampingForce = -velocity * damping
        let combinedForce = springForce + dampingForce
        // a = F/m
        let acceleration = combinedForce
        velocity += acceleration * timeDelta
        value += velocity * timeDelta
    }
}

struct ContentView: View {
    @State var offset: Double = 200
    @State var offsetSpring = SpringDouble(value: 200)
    
    @State var lastDate: Date = Date()
    @State var timeDelta: Double = 0.0
    
    var body: some View {
        HStack(spacing: 40) {
            CircleView(offset: offset)
                .animation(.spring, value: offset)
            
            
            CircleView(offset: offsetSpring.value)
            
        }
        .background {
            TimelineView(.animation) {context in
                Color.clear
                    .onChange(of: context.date) {
                        timeDelta = context.date.timeIntervalSince(lastDate)
                        lastDate = context.date
                        
                        offsetSpring.update(timeDelta: timeDelta)
                    }
            }
        }
        .onTapGesture {
            offset *= -1
            offsetSpring.animate(to: -offsetSpring.target)
        }
    }
}

#Preview {
    ContentView()
}
