using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using extOSC;

public class Sun : OscSinkBase {
    public Material CausticMaterial;
    private Light _sun;
    private float _causticTime = 0.0f;
    private void SetOSCBinding() {
        BindReceive("/brightness", SetBrightness);
        BindReceive("/temperate", SetTemperate);
        BindReceive("/caustic/change", SetCausticChange);
    }

    private void SetBrightness(OSCMessage msg) {
        if (msg.ToFloat(out var f)){
            _sun.intensity = f * f * f * f * 81123.0f;
        }
    }
    private void SetTemperate(OSCMessage msg) {
        if (msg.ToFloat(out var f)){
           // _sun.colorTemperature = f * (20000.0f - 1500.0f) + 1500.0f;
        }
    }
    private void SetCausticChange(OSCMessage msg) {
        if (msg.ToFloat(out var f)){
            _causticTime += f * f * f;
        }
    }

    void Start() {
        _sun = gameObject.GetComponent<Light>();
        SetOSCBinding();
    }

    void Update() {
        CausticMaterial.SetFloat("_TimePos", _causticTime);

    }
}
