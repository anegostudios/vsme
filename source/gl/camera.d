module gl.camera;
import math;
import config;
import components.glviewport;

class Camera {
private:
    EditorViewport parent;
    float rot = 0;

public:
    Vector3 origin;
    Vector3 position;
    Matrix4x4 lookatMatr;
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

    void lookAt(Vector3 point) {
        view = Matrix4x4.look_at(position, point, Vector3(0, 1, 0));
    }

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