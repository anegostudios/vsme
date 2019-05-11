module math;
public import linalg = gl3n.linalg;
public import mathf = gl3n.math;
alias Matrix4x4 = linalg.Matrix!(float, 4, 4);
alias Matrix3x3 = linalg.Matrix!(float, 3, 3);
alias Vector3 = linalg.Vector!(float, 3);
alias Quaternion = linalg.Quaternion!float;
