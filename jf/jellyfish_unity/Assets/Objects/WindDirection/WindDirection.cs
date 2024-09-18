using extOSC;
using UnityEditor;
using UnityEngine;
using Quaternion = UnityEngine.Quaternion;
using Vector3 = UnityEngine.Vector3;

public class WindDirection : OscSinkBase {
	private Vector3 force;

	void Start() {
		BindReceiveGlobal("/global/force", SetForce);
	}

	void SetForce(OSCMessage msg) {
		if (msg.ToVector3(out var s)) {
			s = s * 4.0f - (Vector3.one * 2.0f);
			force = s;
		}
	}

	private void OnDrawGizmos() {
#if UNITY_EDITOR
		Transform transform = gameObject.transform;
		Handles.color = Handles.xAxisColor;
		Quaternion q = Quaternion.FromToRotation(Vector3.forward, force);
		Handles.ArrowHandleCap( 0, transform.position, q, Mathf.Clamp(Vector3.Magnitude(force) * 10f, 0f, 2f) * HandleUtility.GetHandleSize(transform.position), EventType.Repaint );
		Handles.Label(transform.position + new Vector3(0.5f, 0, 0), "Wind Direction");
#endif 
	}
}