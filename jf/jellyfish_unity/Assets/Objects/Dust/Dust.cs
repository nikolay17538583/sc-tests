using extOSC;
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.VFX;
using UnityEngine.VFX.Utility;

public class Dust : OscSinkBase {
	private VisualEffect _vfx;
	
    // Start is called before the first frame update
    void Start() {
        BindReceiveGlobal("/global/force", SetForce);
        BindReceive("/noise", SetNoiseIntensity);
        _vfx = gameObject.GetComponent<VisualEffect>();
    }
	void SetForce(OSCMessage msg) {
		if (msg.ToVector3(out var s)) {
			_vfx.SetVector3("wind", s * 2.0f - new Vector3(1.0f, 1.0f, 1.0f));
		}
	}

	void SetNoiseIntensity(OSCMessage msg) {
		if (msg.ToFloat(out var f)) {
			_vfx.SetFloat("noiseIntensity", f);
		}
	}
}
