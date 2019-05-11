module gl.camera;
import math;
import config;
import components.glviewport;

class Camera {
private:
    EditorViewport parent;

public:
    Vector3 position;
    Matrix4x4 rotation;
    Matrix4x4 projection;

    this(EditorViewport parent) {
        this.parent = parent;
        this.rotation = Matrix4x4.identity();
        this.projection = Matrix4x4.identity();
    }

    Matrix4x4 model() {
        return Matrix4x4.identity();
    }

    Matrix4x4 view() {
        return rotation;
    }

    Matrix4x4 mvp() {
        return (projection * view * model).transposed;
    }

    void  lookat(Vector3 point) {
        rotation = Matrix4x4.look_at(position, point, Vector3(0, 1, 0));
        //rotation = Quaternion.from_matrix();//lookAt(position, point);
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