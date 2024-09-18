using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using extOSC;

public class CameraObj : OscSinkBase {
    public Transform target;
    public Transform defaultTarget;
    private Camera _cam;
    public Camera reflectionCamera;

    private float _interpolate = 0.5f;
    private float _toDefault = 0.0f;

    void Start() {
        _cam = gameObject.GetComponent<Camera>();
        BindReceive("/lookAt/lerp", SetLookAtLerp);
        BindReceive("/force/default", SetLookAtDefault);
        BindReceive("/fov", SetFov);
    }

    void SetFov(OSCMessage msg){
        if (msg.ToFloat(out var f)){
           _cam.fieldOfView = f * 179.0f;
           reflectionCamera.fieldOfView = f * 179.0f;
        }
    }
    void SetLookAtLerp(OSCMessage msg) {
        if (msg.ToFloat(out var s)) {
            _interpolate = s * s * 10.0f;
        }
    }
    void SetLookAtDefault(OSCMessage msg) {
        if (msg.ToFloat(out var s)) {
            _toDefault = s * s * 1.0f;
        }
    }
    void Update() {
        var targetRotation = Quaternion.LookRotation(target.position - transform.position);
        var defaultRotation = Quaternion.LookRotation(defaultTarget.position - transform.position);
        var finalTRot = Quaternion.Lerp(targetRotation, defaultRotation, _toDefault);
        transform.rotation = Quaternion.Lerp(transform.rotation, finalTRot, _interpolate * Time.deltaTime);
        reflectionCamera.transform.rotation = transform.rotation;
    }
}
