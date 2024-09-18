using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using extOSC;
using UnityEngine.VFX;
using UnityEngine.VFX.Utility;


public class Dis : OscSinkBase {
    private VisualEffect _vfx;  
    void Start(){
        _vfx = gameObject.GetComponent<VisualEffect>();
        BindReceive("/displacement", SetDisplacement);
        BindReceive("/blur", SetBlur);
        BindReceive("/force", SetForce);
        BindReceive("/size", SetSize);
    }
    void SetDisplacement(OSCMessage msg){
        if (msg.ToFloat(out var f)){
            _vfx.SetFloat("displacement", f*f*100);
        }
    }
    void SetBlur(OSCMessage msg){
        if (msg.ToFloat(out var f)){
            _vfx.SetFloat("blur", f*f*40);
        }
    }
    void SetForce(OSCMessage msg) {
		if (msg.ToVector3(out var s)) {
			_vfx.SetVector3("force", (s * 5.0f) - new Vector3(2.5f, 2.5f, 2.5f));
		}
	}
    void SetSize(OSCMessage msg){
        if (msg.ToFloat(out var f)){
            _vfx.SetFloat("size", f*f*f*100);
        }
    }
}
