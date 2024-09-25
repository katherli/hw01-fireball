# Project 1: Calcifer!

[Live Demo](https://katherli.github.io/hw01-fireball/)

# Overview

I wanted to make Calcifer from Howl's Moving Castle for my project [(my inspo)](https://youtu.be/c9AnRhKhrvs?si=AFKchNj8s2YTGKpL)! For the eyes and mouth I referenced [this shadertoy](https://www.shadertoy.com/view/stjSDz).

## Noise Generation

- I used a sin function in the vertex shader to apply a low-frequency, high-amplitude displacement to the sphere to make it less uniformly sphere-like.
- In the vertex shader I also applied a higher-frequency, lower-amplitude layer of fractal Brownian motion to apply a finer level of distortion on top of the high-amplitude displacement.
- I created a gradient of flame colors radiating outwards in the fragment shader to represent Howl's heart in the center and applied toon shading to make the shading more like Studio Ghibli's hand-drawn style.
- I combined Perlin and Worley noise to create the flame displacement.
- Toolbox Functions used:
    - Sin functions throughout (mouth displacement, glow pulsing, etc.)
    - Bias (flickering glow, eye blinking)
    - Triangle Wave (eye blinking)
    - Smooth Step (eye and mouth outlines, glow falloff, etc.)

## Interactivity

Interactive variables using dat.GUI:
- Tesselations
- Color (ranges from red to blue to reflect how Calcifer's color changes)
- Intensity (changes size of the flames)
- Speed (changes speed of the flames)
- Reset Scene button to reset the above values

## Extra Spice

- Background (easy-hard depending on how fancy you get): Added a brick background to make it look more like a fireplace
- Custom mesh (easy): Made a cylinder mesh for the log
