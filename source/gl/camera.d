/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module gl.camera;
import math;
import config;
import components.glviewport;

enum CameraMode {
    ArcBall = 0,
    FreeCam = 1
}

enum DEFAULT_DIST = 5;
enum DEFAULT_DIST_ORTHO = 50;

class Camera {
private:
    EditorViewport parent;

public:
    CameraMode mode = CameraMode.ArcBall;

    float distance = DEFAULT_DIST;
    Quaternion rotation = Quaternion.identity;
    Vector3 origin, targetOrigin;
    
    Matrix4x4 view;
    Matrix4x4 projection;

    this(EditorViewport parent) {
        this.parent = parent;
        this.view = Matrix4x4.identity();
        this.projection = Matrix4x4.identity();
        this.origin = this.targetOrigin = Vector3(0, 0, 0);
    }

    Matrix4x4 mvp() {
        return projection * view;
    }

    void transformView() {
        if (this.distance < CONFIG.camera.znear) this.distance = CONFIG.camera.znear;
        Matrix4x4 positionMatrix = Matrix4x4.identity();
        positionMatrix *= Matrix4x4.translation(Vector3(0, 0, -distance));
        positionMatrix *= rotation.to_matrix!(4, 4);
        positionMatrix *= Matrix4x4.translation(-origin);
        //positionMatrix *= rotation.to_matrix!(4, 4);
        view = positionMatrix;
    }

    void changeFocus(Vector3 focusItem, float distance) {
        move(focusItem, false);
        this.distance = distance;
    }

    /*void lookAt(Vector3 point) {
        view = Matrix4x4.look_at(position, point, Vector3(0, 1, 0));
    }*/

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

    void offset(Vector3 offset, bool instant = false) {
        move(targetOrigin + offset, instant);
    }

    void move(Vector3 position, bool instant = false) {
        targetOrigin = position;
        if (instant)
            origin = targetOrigin;
    }
}