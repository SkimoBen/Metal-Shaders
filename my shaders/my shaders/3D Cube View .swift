//
//  3D Cube View .swift
//  my shaders
//
//  Created by Ben Pearman on 2024-07-19.
//

import SwiftUI

struct ImageExplosionView: View {
    @State var touch = CGPoint.zero
    @State var start = Date.now
    @State var angle = 0.0
    @State var amplitude = 0.01
    @State var frequency = 0.1
    var body: some View {
        
        VStack {
//            HStack {
//                Text("Amplitude")
//                Text("\(String(amplitude))")
//            }
//            Slider(value: $amplitude, in: -1...10)
//            
//            HStack {
//                Text("Angle")
//                Text("\(String(angle))")
//            }
//            Slider(value: $angle, in: 0.0...40)
//            
//            HStack {
//                Text("frequency")
//                Text("\(String(frequency))")
//            }
//            Slider(value: $frequency, in: -2.0...20)
            
            
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                Image("yuta energy")
                    .resizable()
                    .scaledToFit()
                    
//                    .visualEffect { content, geometryProxy in
//                        content.layerEffect(
//                            ShaderLibrary.colorBop(
//                                .float2(touch),
//                                .float2(geometryProxy.size)
//                            ),
//                            maxSampleOffset: .zero)
//                    }
                    .visualEffect { content, geometryProxy in
                        content.layerEffect(
                            ShaderLibrary.ConvergingEnergyLines(
                                .float2(touch),
                                .float2(geometryProxy.size),
                                .float(time)
                                //.float(angle),
                                //.float(amplitude),
                                //.float(frequency)
                                
                            ),
                            maxSampleOffset: .zero)
                    }
                    
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { touch = $0.location }
                    )
            }
        }
    }
}



#Preview {
    ImageExplosionView()
}
