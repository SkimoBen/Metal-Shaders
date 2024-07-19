//
//  MetalTesting.metal
//  my shaders
//
//  Created by Ben Pearman on 2024-07-18.
//
//

// Holy trinity of Metal is colorEffect, distortionEffect, and layerEffect.


#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;


// ---------colorEffect----------
// Make it the same color value
[[ stitchable ]] half4 passthrough(float2 pos, half4 color) {
    return color;
}

// Make it red
[[ stitchable ]] half4 recolor( float2 pos, half4 color) {
    return half4(1,0,0,color.a);
}

// Invert the transparency
[[stitchable]] half4 invertAlpha(float2 pos, half4 color) {
    return half4(1,0,0,1 - color.a);
}

// Color Gradient
[[stitchable]] half4 gradient(float2 pos, half4 color) {
    return half4(
                 pos.x / pos.y,
                 0,
                 pos.y / pos.x,
                 color.a
                 );
}

// Rainbow effect

[[ stitchable ]] half4 rainbow(float2 pos, half4 color, float time) {
    float angle = atan2(pos.y, pos.x) + time;
    
    return half4(
                 sin(angle),
                 sin(angle + 2),
                 sin(angle + 4),
                 color.a
                 );
}

// ------------Distorition effects----------
// wave filter

[[stitchable]] float2 wave(float2 pos, float time) {
    pos.y += sin(time * 5 + pos.y / 5) * 5;
    //pos.x += sin(time * 5 + pos.x / 5) * 2;
    return pos;
}

// relative wave filter

[[stitchable]] float2 relativeWave(float2 pos, float time, float2 size) {
    float2 distance = pos / size;
    pos.y += sin(time * 5 + pos.y / 20) * distance.x * 10;
    
    return pos;
}


// -------- Layer Effects ---------

// loupe effect makes a nice fish bowl magnifier.
[[stitchable]] half4 loupe(float2 pos, SwiftUI::Layer layer, float2 size, float2 touch) {
    
    float maxDistance = 0.05;
    float2 uv = pos / size;
    float2 center = touch / size;
    float2 delta = uv - center;
    float aspectRatio = size.x / size.y;
    
    // pythagorean theorem, how far is the touch point from the pixel(for every pixel)
    float distance = (delta.x * delta.x) + (delta.y * delta.y) / aspectRatio;
    
    float totalZoom = 1;
    
    if (distance < maxDistance) {
        totalZoom /= 2;
        totalZoom += distance * 10;
    }
    float2 newPos = delta * totalZoom + center;
    return layer.sample(newPos * size);
}

// Shape Transition
// makes a bunch of circles, looks dumb lol.
[[stitchable]] half4 circles(float2 pos, half4 color, float2 size, float amount) {
    //float2 uv = pos / size;
    float strength = 20;
    float2 f = fract(pos / strength);
    float d = distance(f, 0.5); //calculate distance
    
    if (d < amount) {
        return color;
    } else {
        return 0;
    }
}



// MARK: Single Sine Wave
[[stitchable]] half4 sineWave(float2 pos, half4 color, float2 size, float time) {
    // Normalize position
    float2 uv = pos / size;
    
    // Adjust sine wave parameters
    float frequency = 10.0; // number of waves
    float amplitude = 0.05;  // wave height
    float speed = 1.0;      // wave speed
    
    // Calculate the sine wave pattern
    float wave = sin((uv.x + time * speed) * frequency) * amplitude;
    
    // Check if the current position is within the sine wave range
    float wavePosition = 0.5 + wave; // Center the wave vertically
    float threshold = 0.01;          // Thickness of the wave
    
    // Determine the color based on the wave position
    if (abs(uv.y - wavePosition) < threshold) {
        return color; // Color the sine wave
    } else {
        return half4(0.0, 0.0, 0.0, 1.0); // Black background
    }
}

//MARK: dragging warp thing. It looks sick
[[stitchable]] half4 w(float2 pos,SwiftUI::Layer layer,float2 touch,float2 size){
    float2 displacement =- size * pow(clamp(1-length(touch-pos)/190,0.,1.),2)*1.5;
    half3 color=0;
    for(float i=0; i<10; i++){
        float s = .175 + .005 * i;
        //Sample each channel from a different position, average it out 10 times.
        color += half3(layer.sample(pos+s*displacement).r,layer.sample(pos + (s + .025)*displacement).g, layer.sample(pos+(s + .05)*displacement).b);
        
    }
    return half4(color/10,1);
}


// Pseudo-random number generator
float random(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

[[stitchable]] half4 explosion(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size) {
    float maxDistance = 0.05; // max distance from touch point

    float2 uv = pos / size;
    float2 center = touch / size;
    float2 delta = uv - center;
    float aspectRatio = size.x / size.y;
    
    // Pythagorean theorem, how far is the touch point from the pixel (for every pixel)
    float distance = (delta.x * delta.x) + (delta.y * delta.y) / aspectRatio;
    
    float totalZoom = 1; // Zoom of the entire layer
    
    if (distance < maxDistance) {
        totalZoom /= 2;
        totalZoom += distance * 10; // This makes the effect fall off gently
    }
    
    float2 newPos = delta * totalZoom + center;
    half4 sampledColor = layer.sample(newPos * size);
    
    // Blend factor based on distance, 1 at the touch point, 0 at the edge of the effect
    float blendFactor = 1.0 - (distance / maxDistance);
    blendFactor = clamp(blendFactor, 0.0, 1.0);
    
    half4 adjustedColor = sampledColor;

    // Apply 10 different random tint colors
    for (int i = 0; i < 10; ++i) {
        // Generate a random tint color
        //float seed = i;
        float r = random(i, i, i) * 0.9;
        float g = random(i, i, i) * 0.2;
        float b = random(i, i, i) * 0.2;
        half4 tintColor = half4(r, g, b, 1.0);
        
        // Adjust the sampled color towards the random tint color
        adjustedColor = mix(adjustedColor, tintColor, half(blendFactor) * 0.1); // Each blend has a smaller factor
    }
    
    return adjustedColor;
}


//MARK: TOUCH BASED COLOR INVERTER simpleColorShift: Inverts the color around the users touch point

[[stitchable]] half4 simpleColorShift(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size) {
    // ----Make the effect happen in a circle around the touch point
    float maxDistance = 0.05; // max distance from touch point

    float2 uv = pos / size;
    float2 center = touch / size;
    
    float2 delta = uv - center;
    
    float aspectRatio = size.x / size.y;
    
    // Pythagorean theorem, how far is the touch point from the pixel (for every pixel)
    float distance = (delta.x * delta.x) + (delta.y * delta.y) / aspectRatio;
    
    //float totalZoom = 1; // Zoom of the entire layer
    half4 currentColor = layer.sample(pos);
    half4 newColor = currentColor;
    
    if (distance < maxDistance) {
        half4 invertedColor = half4(1-currentColor.r, 1-currentColor.g, 1-currentColor.b, 1);
        
        invertedColor += distance * 20; // This makes the effect fall off gently
        newColor = invertedColor;
    }
    //------
    
    return newColor;
    
}


//MARK: Inverted Color Sine Wave
[[stitchable]] half4 staticSineWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time) {
    // Normalize position
    float2 uv = pos / size;
    
    // Adjust sine wave parameters
    float frequency = 3.0; // number of waves
    float amplitude = 0.05;  // wave height
    float speed = 1.0;      // wave speed
    
    // Calculate the sine wave pattern
    float wave = sin((uv.x + time * speed) * frequency) * amplitude;
    
    // Check if the current position is within the sine wave range
    float wavePosition = 0.5 + wave; // Center the wave vertically
    float threshold = 0.01;          // Thickness of the wave
    
    half4 currentColor = layer.sample(pos);
    
    // Determine the color based on the wave position
    if (abs(uv.y - wavePosition) < threshold) {
        return layer.sample(pos); // Color the sine wave
    } else {
        half4 invertedColor = half4(1-currentColor.r, 1-currentColor.g, 1-currentColor.b, 1);
        
        invertedColor += wave; // This makes the effect fall off gently
        return invertedColor;
    }
    
}

//MARK: METAL EVERYTHING :: THE SINEBOW

[[stitchable]] half4 sinebow(float2 pos, half4 color, float2 size, float time) {
    float2 uv = (pos / size.x) * 1-1; // makes UV in range of -1 to +1
    uv.y += 0.15;
    float wave = sin(uv.x + time);
    wave *= wave * 50;
    
    half3 waveColor = half3(0);
    for (float i = 0; i < 10; i++) {
        // i is the number of lines, and the level of brightness
        float luma = abs(1 / (100 * uv.y + wave));
        
        
        float y = sin(uv.x * sin(time) + i * 0.2 + time);
        uv.y -= 0.05 * y;
        half3 rainbow = half3(
                              sin(i * 0.3 + time) * 0.5 + 0.5,
                              sin(i * 0.3 + 2 + sin(time*0.3) * 2) * 0.5+ 0.5,
                              sin(i * 0.3 + 4) * 0.5 + 0.5
                              );
        waveColor += rainbow * luma;
        
    }
    return half4(waveColor, 1);
}

//MARK: Rotatable Sine Wave
[[stitchable]] half4 rotatedSineWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time, float angleDivisor) {
    // Normalize position
    float2 uv = pos / size;
    
    // Adjust sine wave parameters
    float frequency = 3.0; // number of waves
    float amplitude = 0.05;  // wave height
    float speed = 1.0;      // wave speed
    float angle = 3.14159 / angleDivisor; // Angle in radians
    
    // Calculate the sine wave pattern with angle
    float2 rotatedUV = float2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
    float wave = sin((rotatedUV.x + time * speed) * frequency) * amplitude;
    
    // Check if the current position is within the sine wave range
    float wavePosition = rotatedUV.y - wave; // Adjust wave position based on rotated coordinates
    float threshold = 0.01;          // Thickness of the wave
    
    half4 currentColor = layer.sample(pos);
    
    // Determine the color based on the wave position
    if (abs(wavePosition) < threshold) {
        return layer.sample(pos); // Color the sine wave
    } else {
        half4 invertedColor = half4(1-currentColor.r, 1-currentColor.g, 1-currentColor.b, 1);
        
        invertedColor += wave; // This makes the effect fall off gently
        return invertedColor;
    }
}

//MARK: Rotatable Parabola
[[stitchable]] half4 rotatedParabola(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time, float angleDivisor) {
    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;
    // Adjust sine wave parameters
    float a = 3.0;   // parabola bend
    float b = center.x;   // parabola intersect position
    float c = center.y;   // parabola tip
    float angle = 3.14159 / angleDivisor; // Angle in radians
    
    // Calculate the sine wave pattern with angle
    float2 rotatedUV = float2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
    float wave = pow(a*rotatedUV.x,2) + (b*rotatedUV.x) + c;
    
    // Check if the current position is within the sine wave range
    float wavePosition = rotatedUV.y - wave; // Adjust wave position based on rotated coordinates
    float threshold = 0.01;          // Thickness of the wave
    
    half4 currentColor = layer.sample(pos);
    
    // Determine the color based on the wave position
    if (abs(wavePosition) < threshold) {
        return layer.sample(pos); // Color the sine wave
    } else {
        half4 invertedColor = half4(1-currentColor.r, 1-currentColor.g, 1-currentColor.b, 1);
        
       // invertedColor += wave; // This makes the effect fall off gently
        return invertedColor;
    }
}

//MARK: New Sine Wave
[[stitchable]] half4 newSineWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time, float angleDivisor, float amplitude, float frequency) {
    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;
    float angle = 3.14159 / angleDivisor; // Angle in radians
    
//    float2 rotatedCenter = float2(
//        center.x * cos(angle) - uv.y * sin(angle),
//        center.x * sin(angle) + uv.y * cos(angle)
//    );
    
    // Adjust sine wave parameters
    float a = amplitude; // Amplitude
    float h = center.x; // X position
    float k = center.y; // Y position
    float b = frequency; // frequency
    
    
    // Calculate the sine wave pattern with angle
    float2 rotatedUV = float2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
    
    // Alternate way of rotating
    float T = 0.5;
    float newWave = cos(T)*center.y - sin(T)*center.x;
    
    float wave = a * sin( ((rotatedUV.x-h)/b)) + k;
    float newWavePosition = uv.y - newWave;
    
    // Check if the current position is within the sine wave range
    float wavePosition = rotatedUV.y - wave; //rotatedUV.y - wave; // Adjust wave position based on rotated coordinates
    float threshold = 0.01;          // Thickness of the wave
    
    half4 currentColor = layer.sample(pos);
    
    // Determine the color based on the wave position
    if (abs(newWavePosition) < threshold) {
        return layer.sample(pos); // Color the sine wave
    } else {
        half4 invertedColor = half4(1-currentColor.r, 1-currentColor.g, 1-currentColor.b, 1);
        
        //invertedColor += wave; // This makes the effect fall off gently
        return invertedColor;
    }
}


// MARK: Rotated Animated Sine Wave
//MARK: THIS WORKS IT'S IMPORTANT
[[stitchable]] half4 anotherNewSineWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time, float angleDivisor, float amplitude, float frequency) {
    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;

    // Define the rotation angle T
    float T = angleDivisor; // Adjust this as needed or make it a parameter
    
    // Calculate the original sine wave position
    float originalWave = amplitude * sin(frequency * (uv.x - center.x) + time);
    
    // Apply the rotation transformation
    float rotatedWaveX = cos(T) * (uv.x - center.x) - sin(T) * (uv.y - center.y);
    float rotatedWaveY = sin(T) * (uv.x - center.x) + cos(T) * (uv.y - center.y);
    
    // Define the wave based on the rotated coordinates
    float wave = amplitude * sin(frequency * rotatedWaveX + time);
    
    // Calculate the wave position
    float wavePosition = rotatedWaveY - wave;
    
    // Define the thickness of the wave
    float threshold = 0.01;
    
    // Sample the current color from the layer
    half4 currentColor = layer.sample(pos);
    
    // Determine the color based on the wave position
    if (abs(wavePosition) < threshold) {
        return layer.sample(pos); // Color the sine wave
    } else {
        half4 invertedColor = half4(1 - currentColor.r, 1 - currentColor.g, 1 - currentColor.b, 1);
        // invertedColor += wave; // Optional: Make the effect fall off gently
        return invertedColor;
    }
}

//MARK: Circle Sine Wave
// Works but the colors are jank
[[stitchable]] half4 circleSineWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time, float angleDivisor, float amplitude, float frequency) {
    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;

    // Define the rotation angle T
    float T = angleDivisor; // Adjust this as needed or make it a parameter
    half3 color = 0;
    // Sample the current color from the layer
    half3 currentColor = half3(layer.sample(pos).r, layer.sample(pos).g, layer.sample(pos).b);
    
    for (float i = 0; i < 10; i++) {
        T = (3.1415 / 10) * i;
        // Apply the rotation transformation
        float rotatedWaveX = cos(T) * (uv.x - center.x) - sin(T) * (uv.y - center.y);
        float rotatedWaveY = sin(T) * (uv.x - center.x) + cos(T) * (uv.y - center.y);
        
        // Define the wave based on the rotated coordinates
        float wave = amplitude * sin(frequency * rotatedWaveX + time);
        
        // Calculate the wave position
        float wavePosition = rotatedWaveY - wave;
        
        // Define the thickness of the wave
        float threshold = 0.01;
        
        
        // Determine the color based on the wave position
        if (abs(wavePosition) < threshold) {
            color = currentColor; // Color the sine wave
        } else {
            half3 invertedColor = half3(1 - (currentColor.r), 1 - (currentColor.g), 1 - (currentColor.b));
            //invertedColor += wave; // Optional: Make the effect fall off gently
            color += invertedColor;
        }
    }
    // Clamp the accumulated color to [0, 1]
    color = clamp(color / 10.0, half3(0.0), half3(1.0));
       
    return half4(color, 1.0);

}


//MARK: Log spiral wave
// This thing is so sick
[[stitchable]] half4 SpiralWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time) {
    // Sample the original layer
    half4 originalColor = layer.sample(pos);

    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;
    
    // Calculate distance from touch point
    float2 delta = uv - center;
    float distance = length(delta);
    
    // Calculate angle
    float angle = atan2(delta.y, delta.x);
    float spiralDiameter = pow(time,2);
    
    // Adjust spiral diameter (smaller values make a larger spiral)
//    if (10/pow(time,2) > 0.2) {
//        spiralDiameter = 10/pow(time,2);
//    } else {
//        spiralDiameter = 0.2;
//    }
    // Adjust this value to change the spiral size
    float adjustedDistance = distance / spiralDiameter;
    
    // Create larger, more chaotic spiral effect with faster spin
    float spinSpeed = pow(2,time); // Increase this value to make it spin faster
    float spiral = sin(adjustedDistance * 10.0 - angle * 8.0 + time * spinSpeed * 4.0) * 0.5 + 0.5;
    //time = 0.01
    for (float i = 0; i < 10; i++) {
        spiral *= sin(adjustedDistance * 1.0 + angle * 6.0 - time * 3.0) * 0.5 + 0.5;
        spiral *= sin(adjustedDistance * 20.0 * pow(time,2) - angle * 4.0 + time * spinSpeed * 5.0) * 0.5 + 0.5;
        spiral /= sin(adjustedDistance * 27.0 * pow(time,i) - angle * 4.0 + time * spinSpeed * 5.0) * 0.5 + 0.5;
        //spiralDiameter += time/2;
    }
    
    // Extend the fade-out range for a larger effect
    float fade = smoothstep(0.8 * spiralDiameter, 0.2 * spiralDiameter, distance);
    
    // Sample original color components
    half3 originalColor3 = half3(originalColor.r, originalColor.g, originalColor.b);
    
    // Create inverted color with varying intensity
    half3 spiralColor = half3(1 - originalColor3.r, 1 - originalColor3.g, 1 - originalColor3.b) * spiral * fade;
    
    // Add some color variation based on angle with faster spin
    spiralColor *= half3(
        0.8 + 0.2 * sin(angle * 3.0 + time * spinSpeed),
        0.8 + 0.2 * sin(angle * 4.0 - time * spinSpeed),
        0.8 + 0.2 * cos(angle * 5.0 + time * spinSpeed * 0.5)
    );
    
    // Blend spiral effect with original color
    half3 blendedColor = mix(originalColor.rgb, spiralColor, fade * spiral * 0.8);
    
    // Return final color, preserving original alpha
    return half4(blendedColor, originalColor.a);
}


//MARK: Color Banger (looks like a cd filter where you touch)
[[stitchable]] half4 colorBop(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size) {
    // Reduce the displacement effect
    float2 displacement = -size * pow(clamp(1 - length(touch - pos) / 250, 0., 1.), 3) * 0.5;
    
    half3 color = 0;
    half3 originalColor = layer.sample(pos).rgb;
    
    for (float i = 0; i < 10; i++) {
        float s = 0.05 + 0.009 * i;  // Reduced scale factor
        
        // Sample each channel from a different position, but with less displacement
        color += half3(
            layer.sample(pos + s * displacement).r,
            layer.sample(pos + (s + 0.001) * displacement).g,
            layer.sample(pos + (s + 0.002) * displacement).b
        );
    }
    
    // Blend the color effect with the original color
    half3 blendedColor = mix(originalColor, color / 10, 0.6);
    
    return half4(blendedColor, 1);
}

[[stitchable]] half4 FixedDSpiralWave(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time) {
    // Sample the original layer
    half4 originalColor = layer.sample(pos);

    // Normalize position
    float2 uv = pos / size;
    float2 center = touch / size;
    
    // Calculate distance from touch point
    float2 delta = uv - center;
    float distance = length(delta);
    float sprialDiameter = 1.0;
    distance = distance / sprialDiameter;
    // Calculate angle
    float angle = atan2(delta.y, delta.x);
    
    // Create larger, more chaotic spiral effect with faster spin
    float spinSpeed = 2.0; // Increase this value to make it spin faster
    float spiral = sin(distance * 10.0 - angle * 8.0 + time * spinSpeed * 4.0) * 0.5 + 0.5;
    
    for (float i=0; i<5; i++){
        spiral *= sin(distance/2 * 15.0 + angle * 6.0 - time * 3.0) * 0.5 + 0.5;
        spiral *= sin(distance * 20.0 * time - angle * 4.0 + time * spinSpeed * 5.0) * 0.5 + 0.5;
        spiral /= tan(distance * 20.0 * i - angle * 4.0 + time * spinSpeed * 5.0) * 0.5 + 0.5;
    }
    
    
    // Extend the fade-out range for a larger effect
    float fade = smoothstep(0.8, 0.2, distance);
    
    // Sample original color components
    half3 originalColor3 = half3(originalColor.r, originalColor.g, originalColor.b);
    
    // Create inverted color with varying intensity
    half3 spiralColor = half3(1-originalColor3.r, 1 - originalColor3.g, 1 - originalColor3.b) * spiral * fade;
    
    // Add some color variation based on angle with faster spin
    spiralColor *= half3(
        0.8 + 0.2 * sin(angle * 3.0 + time * spinSpeed),
        0.8 + 0.2 * sin(angle * 4.0 - time * spinSpeed),
        0.8 + 0.2 * cos(angle * 5.0 + time * spinSpeed * 0.5)
    );
    
    // Blend spiral effect with original color
    half3 blendedColor = mix(originalColor.rgb, spiralColor, fade * spiral * 0.8);
    
    // Return final color, preserving original alpha
    return half4(blendedColor, originalColor.a);
}

//MARK: Flying Lines
[[stitchable]] half4 ConvergingEnergyLines(float2 pos, SwiftUI::Layer layer, float2 touch, float2 size, float time) {
    // Sample the original layer
    half4 originalColor = layer.sample(pos);
    
    
    // Define the y-coordinate for the line (centered vertically)
    float lineY = size.y * 0.5;
    
    // Define the thickness of the line
    float lineThickness = 1.0; // Adjust this value for desired thickness
    
    // Define the length of the line
    float lineLength = size.x * 0.5; // Adjust this value for desired length (e.g., half the screen width)
    
    // Calculate the distance from the current pixel to the line
    float distanceToLine = abs(pos.y - lineY);
    
    // Check if the current pixel is within the thickness of the line
    if (distanceToLine < lineThickness) {
        // Check if the current pixel is within the horizontal bounds of the line
        float startX = (size.x - lineLength) * 0.5;
        float endX = (size.x + lineLength) * 0.5;
        if (pos.x >= startX && pos.x <= endX) {
            // Set the color of the line (e.g., white)
            return half4(1.0, 0.0, 1.0, 1.0);
        }
    }
    
    // Return the original color for other pixels
    return originalColor;
    
}

