import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cylinder extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3, public radius: number, public length: number, public radialSegments: number,
    public lengthSegments: number) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {
    const radialSegments = Math.max(3, Math.floor(this.radialSegments));
    const lengthSegments = Math.max(1, Math.floor(this.lengthSegments));
    const halfLength = this.length / 2;

    const positions = new Array<number>();
    const normals = new Array<number>();
    const indices = new Array<number>();

    // Side vertices and normals
    for (let i = 0; i <= lengthSegments; i++) {
      const x = -halfLength + (i / lengthSegments) * this.length;
      for (let j = 0; j <= radialSegments; j++) {
        const theta = (j / radialSegments) * 2 * Math.PI;
        const sinTheta = Math.sin(theta);
        const cosTheta = Math.cos(theta);

        const y = this.radius * cosTheta;
        const z = this.radius * sinTheta;

        positions.push(x + this.center[0], y + this.center[1], z + this.center[2], 1.0);
        normals.push(0.0, cosTheta, sinTheta, 0.0);
      }
    }

    // Generate side indices
    for (let i = 0; i < lengthSegments; i++) {
      for (let j = 0; j < radialSegments; j++) {
        const base = i * (radialSegments + 1) + j;
        const a = base;
        const b = base + radialSegments + 1;
        const c = base + 1;
        const d = base + radialSegments + 2;

        // First triangle
        indices.push(a, b, c);

        // Second triangle
        indices.push(c, b, d);
      }
    }

    // Generate caps
    // Top cap (positive x-direction)
    const topCenterIndex = positions.length / 4;
    positions.push(halfLength + this.center[0], this.center[1], this.center[2], 1.0); // Center of top cap
    normals.push(1.0, 0.0, 0.0, 0.0); // Normal pointing along +x

    for (let j = 0; j <= radialSegments; j++) {
      const theta = (j / radialSegments) * 2 * Math.PI;
      const sinTheta = Math.sin(theta);
      const cosTheta = Math.cos(theta);

      const y = this.radius * cosTheta;
      const z = this.radius * sinTheta;

      positions.push(halfLength + this.center[0], y + this.center[1], z + this.center[2], 1.0);
      normals.push(1.0, 0.0, 0.0, 0.0); // Normal pointing along +x
    }

    // Indices for top cap
    for (let j = 0; j < radialSegments; j++) {
      const centerIndex = topCenterIndex;
      const firstIndex = topCenterIndex + 1 + j;
      const secondIndex = topCenterIndex + 1 + ((j + 1) % (radialSegments + 1));

      indices.push(centerIndex, firstIndex, secondIndex);
    }

    // Left end
    const bottomCenterIndex = positions.length / 4;
    positions.push(-halfLength + this.center[0], this.center[1], this.center[2], 1.0); // Center of bottom cap
    normals.push(-1.0, 0.0, 0.0, 0.0); // Normal pointing along -x

    for (let j = 0; j <= radialSegments; j++) {
      const theta = (j / radialSegments) * 2 * Math.PI;
      const sinTheta = Math.sin(theta);
      const cosTheta = Math.cos(theta);

      const y = this.radius * cosTheta;
      const z = this.radius * sinTheta;

      positions.push(-halfLength + this.center[0], y + this.center[1], z + this.center[2], 1.0);
      normals.push(-1.0, 0.0, 0.0, 0.0); // Normal pointing along -x
    }

    // Indices for left circle
    for (let j = 0; j < radialSegments; j++) {
      const centerIndex = bottomCenterIndex;
      const firstIndex = bottomCenterIndex + 1 + ((j + 1) % (radialSegments + 1));
      const secondIndex = bottomCenterIndex + 1 + j;

      indices.push(centerIndex, firstIndex, secondIndex);
    }

    this.positions = new Float32Array(positions);
    this.normals = new Float32Array(normals);
    this.indices = new Uint32Array(indices);

    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    console.log(`Created cylinder with ${this.positions.length / 4} vertices`);
  }
}

export default Cylinder;
