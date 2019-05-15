/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module gl.camera;
import components.glviewport;
import config;
import math;

/// The modes the camera can be in
enum CameraMode {
    ArcBall = 0,
    FreeCam = 1
}

/// The default distance of which the camera will be placed away from an object.
enum DEFAULT_DIST = 5;

/++
    Camera implements an ArcBall camera for use in the application

    It will eventually also have a free cam mode.
+/
class Camera {
private:
    EditorViewport parent;
    Vector3 targetOrigin;

public:
    /// The camera mode
    CameraMode mode = CameraMode.ArcBall;

    /// The distance from the origin/target
    float distance = DEFAULT_DIST;

    /// The rotation of the camera based of origin
    Quaternion rotation = Quaternion.identity;

    /// The origin of the camera
    Vector3 origin;
    
    /// The view matrix (what the camera sees)
    Matrix4x4 view;

    /// The projection matrix (what the user sees)
    Matrix4x4 projection;

    this(EditorViewport parent) {
        this.parent = parent;
        this.view = Matrix4x4.identity();
        this.projection = Matrix4x4.identity();
        this.origin = this.targetOrigin = Vector3(0, 0, 0);
    }

    /// Calculate an MVP matrix
    Matrix4x4 mvp() {
        /// Model part is calculated in the NodeElement class.
        return projection * view;
    }

    /// Handle the viewport transformation.
    void transformView() {
        if (this.distance < CONFIG.camera.znear) this.distance = CONFIG.camera.znear;
        Matrix4x4 positionMatrix = Matrix4x4.identity();
        positionMatrix *= Matrix4x4.translation(Vector3(0, 0, -distance));
        positionMatrix *= rotation.to_matrix!(4, 4);
        positionMatrix *= Matrix4x4.translation(-origin);
        view = positionMatrix;
    }

    /// Switch the focus from one origin to another.
    void changeFocus(Vector3 focusItem, float distance) {
        move(focusItem, false);
        this.distance = distance;
    }

    /// Update the camera's matricies and position
    void update(double deltaTime) {
        origin = (origin - targetOrigin) * pow(1e-4f, deltaTime) + targetOrigin;
        if (CONFIG.camera.perspective) {
            projection = Matrix4x4.perspective(cast(float)parent.width, cast(float)parent.height, CONFIG.camera.fov, CONFIG.camera.znear, CONFIG.camera.zfar);
        } else {
            float w = cast(float)parent.width;
            float h = cast(float)parent.height;
            
            float r = 0;
            
            if (w < h) r = w;
            else r = h;

            float distx = (distance/2);
            if (distx < CONFIG.camera.znear) distx = CONFIG.camera.znear;

            float w_d = (w/r)*distx;
            float h_d = (h/r)*distx;
            projection = Matrix4x4.orthographic(-w_d, w_d, -h_d, h_d, CONFIG.camera.znear, CONFIG.camera.zfar);
        }
    }

    /++
        Offset the camera's origin by desired value.

        If instant is false the camera will smoothly move over to that point,
        Otherwise it'll instantly snap to that point.
    +/
    void offset(Vector3 offset, bool instant = false) {
        move(targetOrigin + offset, instant);
    }

    /++
        Moves camera origin to a specific position in the world.

        If instant is false the camera will smoothly move over to that point,
        Otherwise it'll instantly snap to that point.
    +/
    void move(Vector3 position, bool instant = false) {
        targetOrigin = position;
        if (instant)
            origin = targetOrigin;
    }
}