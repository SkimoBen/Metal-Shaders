//
//  ContentView.swift
//  my shaders
//
//  Created by Ben Pearman on 2024-07-18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        VStack {
            Spacer()
            //timeView()
            //touchView()
            //SineBowView()
            //PencilSketch()
            //TextView()
            //ImageExplosionView()
            //Spacer()
        }
    }
}

#Preview {
    ContentView()
}

// This is for time based shaders.
struct timeView: View {
    @State var start = Date.now
    var body: some View {
        VStack {
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                
                Image("heart")
                    .resizable()
                    .scaledToFit()
                    .padding(60)
                    .visualEffect { content, geometryProxy in
                        content
                            .distortionEffect(
                                ShaderLibrary.relativeWave(
                                    .float(time),
                                    .float2(geometryProxy.size)
                                ),
                                maxSampleOffset: .zero
                            )
                    }
            }
            
        }
    }
}

// this is for touch based shaders
struct touchView: View {
    @State var touch = CGPoint.zero
    var body: some View {
        VStack {
            Image("heart")
                .resizable()
                .scaledToFit()
                .padding(60)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(
                            //pos and layer get passed in automatically for some reason.
                            ShaderLibrary.loupe(
                                .float2(geometryProxy.size),
                                .float2(touch)
                            ),
                            maxSampleOffset: .zero
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { touch = $0.location }
                )
        }
    }
}

// This is for time based shaders.
struct SineBowView: View {
    @State var start = Date.now
    var body: some View {
        
        VStack {
            Spacer()
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                Rectangle()
                    .frame(height:500)
                    .visualEffect { content, geometryProxy in
                        content.colorEffect(
                            ShaderLibrary.sinebow(
                                .float2(geometryProxy.size),
                                .float(time)
                            )
                        )
                    }
                    .border(Color.red)
                    .padding(20)
                    .background(.white)
                    .drawingGroup()
            
            }
            Spacer()
        }
        
    }
}

// This is for time based shaders.
struct PencilSketch: View {
    @State var start = Date.now
    var body: some View {
        
        VStack {
            Spacer()
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                Image("heart")
                    .frame(height:500)
                    .visualEffect { content, geometryProxy in
                        content.colorEffect(
                            ShaderLibrary.sineWave(
                                .float2(geometryProxy.size),
                                .float(time)
                            )
                        )
                    }
                    .border(Color.red)
                    .padding(20)
                    .background(.blue)
                    .drawingGroup()
            
            }
            Spacer()
           
        }
        
    }
}

struct TextView: View {
    @State var touch = CGPoint.zero
    var body: some View {
        VStack {
            Text("Hello Word Hello World Hello Word Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World")
                .font(.system(size: 70)) // Adjust the font size as needed
                .lineLimit(nil) // Allow unlimited lines
                .multilineTextAlignment(.center) // Center the text (optional)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the screen
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(
                            //pos and layer get passed in automatically for some reason.
                            ShaderLibrary.w(
                                .float2(touch),
                                .float2(geometryProxy.size)
                                
                            ),
                            maxSampleOffset: .zero
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { touch = $0.location }
                )
        }
        .background(Color.gray)
        //.padding() // Add padding if needed
    }
}
