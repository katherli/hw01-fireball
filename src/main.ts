//test
import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import Cylinder from './geometry/Cylinder';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Reset Scene': loadScene, // A function pointer, essentially
  Color: 0,
  Intensity: 1.2,
  Speed: 1
};

let square: Square
let body: Icosphere;
let prevTesselations: number = 5;
let time: number = 0;
let log: Cylinder;

function loadScene() {
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  body = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  body.create();
  log = new Cylinder(vec3.fromValues(0, -1.5, 0), 1, 5, 32, 1);
  log.create();
  controls.tesselations = 5;
  controls.Color = 0;
  controls.Intensity = 1.2;
  controls.Speed = 1;
}

function lerpColor(minColor: vec3, maxColor: vec3, t: number): vec3 {
  return vec3.lerp(vec3.create(), minColor, maxColor, t);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Color', 0, 1).step(0.01);
  gui.add(controls, 'Intensity', 0, 4).step(0.1);
  gui.add(controls, 'Speed', 0.1, 2).step(0.01)
  gui.add(controls, 'Reset Scene');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  //custom shaders
  const bodyShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/body-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/body-frag.glsl')), 
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/background-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl')),
  ]);

  const redColor = vec3.fromValues(1.0, 0.0, 0.0);   // Red color
  const blueColor = vec3.fromValues(0.0, 0.0, 1.0);  // Blue color

  // This function will be called every frame
  function tick() {
    time++; 
    const currentTime = time * 0.1;
    bodyShader.setTime(currentTime);

    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      body = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      body.create();
    }

    const color = lerpColor(redColor, blueColor, controls.Color);
    const finalColor = vec4.fromValues(color[0], color[1], color[2], 1.0);
    const intensity = controls.Intensity;
    const timeOffset = controls.Speed;

    renderer.render(camera, background, vec4.fromValues(1, 1, 1, 1), currentTime, [
      square
    ], intensity, timeOffset);

    //const color = vec4.fromValues(controls.Color[0] / 255.0, controls.Color[1] / 255.0, controls.Color[2] / 255.0, controls.Color[3]);
    renderer.render(camera, bodyShader, finalColor, currentTime, [
      body, 
      //square,
      //cube
    ], intensity, timeOffset); 

    renderer.render(camera, lambert, finalColor, currentTime, [
      log, 
      //square,
      //cube
    ], intensity, timeOffset); 
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
