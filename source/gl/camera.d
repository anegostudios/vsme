module gl.camera;
import math;
import config;
import components.glviewport;

enum CameraMode {
    ArcBall = 0,
    FreeCam = 1
}

class Camera {
private:
    EditorViewport parent;

public:
    CameraMode mode = CameraMode.ArcBall;

    float distance = 5;
    float rotationX = 0;
    float rotationY = 0;
    Vector3 origin;
    
    Matrix4x4 view;
    Matrix4x4 projection;

    this(EditorViewport parent) {
        this.parent = parent;
        this.view = Matrix4x4.identity();
        this.projection = Matrix4x4.identity();
        this.origin = Vector3(0, 0, 0);
    }

    Matrix4x4 mvp() {
        return projection * view;
    }

    void transformView() {
        import std.stdio;
        Matrix4x4 positionMatrix = Matrix4x4.translation(origin);
        positionMatrix *= Matrix4x4.translation(Vector3(0, 0, -distance));
        positionMatrix *= Matrix4x4.xrotation(rotationX);
        positionMatrix *= Matrix4x4.yrotation(rotationY);
        //positionMatrix *= rotation.to_matrix!(4, 4);
        view = positionMatrix;
    }

    void changeFocus(Vector3 focusItem, float distance) {
        origin = focusItem;
        this.distance = distance;
        if (this.distance < 0) this.distance = 0.1f;
    }

    /*void lookAt(Vector3 point) {
        view = Matrix4x4.look_at(position, point, Vector3(0, 1, 0));
    }*/

    void update() {
        if (CONFIG.camera.perspective) {
            projection = Matrix4x4.perspective(cast(float)parent.width, cast(float)parent.height, CONFIG.camera.fov, CONFIG.camera.znear, CONFIG.camera.zfar);
        } else {
            float w = cast(float)parent.width;
            float h = cast(float)parent.height;
            
            float r = 0;
            
            if (w < h) r = w;
            else r = h;

            float w_d = (w/r)*(r/CONFIG.camera.fov);
            float h_d = (h/r)*(r/CONFIG.camera.fov);
            projection = Matrix4x4.orthographic(-w_d, w_d, -h_d, h_d, CONFIG.camera.znear, CONFIG.camera.zfar);
        }
    }
}