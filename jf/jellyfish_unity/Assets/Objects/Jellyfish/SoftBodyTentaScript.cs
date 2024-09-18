using System;
using System.Runtime.InteropServices;
using extOSC;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteAlways]
public class SoftBodyTentaScript : OscSinkBase {
	public ComputeShader tentaComputeShader;

	#region OSC Bindings

	private void StartOSCBind() {
		BindReceiveGlobal("/global/force", SetForce);

		BindReceive("/position", SetPosition);
		BindReceive("/position/large", SetLargePosition);

		BindReceive("/rotation", SetRotation);

		BindReceive("/noise/scale", SetNoiseScale);
		BindReceive("/noise/strength", SetNoiseForce);

		BindReceive("/tension", SetTensionForce);

		BindReceive("/decay", SetDecay);

		BindReceive("/width", SetWidth);

		BindReceive("/noise/timescale", SetNoiseTimeScale);

		BindReceive("/thickness", SetThickness);
		BindReceive("/texture/velocity", SetTextureVelocity);
		BindReceive("/texture/rotate", SetTextureRotate);
		BindReceive("/texture/unique", SetTextureUnique);

		BindReceive("/brightness", SetBrightness);
		BindReceive("/tint", SetTint);
		BindReceive("/shape", SetShape);
	}

	#endregion

	#region Custom Structs

	[VFXType(VFXTypeAttribute.Usage.GraphicsBuffer)]
	private struct TentaPoint {
		public Vector3 Velocity;
		public Vector3 TargetPosition;
	}

	[Serializable]
	private struct TentaOptions {
		public int numStrands;
		public float timeStep;

		public Vector3 origin;
		public Vector4 rotation;

		public Vector3 globalForce;

		public Vector2 noiseScale;
		public float noiseStrength;

		public float tensionStrength;

		public float velocityDecay;
		public float width;
		public float time;

		public float shape;
	}

	#endregion

	#region Private members

	private VisualEffect _vfx;

	private readonly int _vfxDataID = Shader.PropertyToID("TentaPoints");
	private readonly int pointsPerStrip = 128; // must be multiple of 64
	private readonly int numStrips = 200;
	private GraphicsBuffer _tentaPoints;

	private readonly TentaOptions[] _tOpts = new TentaOptions[1];
	private GraphicsBuffer _tentaOptions;


	private int _computeKernelInit;
	private int _computeKernelMain;

	private float _timeInternalCounter;
	private float _timeRate = 1.0f;

	#endregion

	#region OSC Setters

	#region VFX

	private void SetBrightness(OSCMessage msg) {
		if (msg.ToFloat(out float s)) _vfx.SetFloat("Brightness", s);
	}

	private void SetTint(OSCMessage msg) {
		if (msg.ToFloat(out float s)) _vfx.SetFloat("Tint", s);
	}

	private void SetTextureRotate(OSCMessage msg) {
		if (msg.ToFloat(out float v)) _vfx.SetFloat("textureRotate", v);
	}

	private void SetThickness(OSCMessage msg) {
		if (msg.ToFloat(out float s)) _vfx.SetFloat("width", s);
	}

	private void SetTextureUnique(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _vfx.SetFloat("textureUnique", f);
	}

	private Vector2 _texturePosition;

	private void SetTextureVelocity(OSCMessage msg) {
		if (msg.ToVector2(out Vector2 v)) {
			_texturePosition += v * 2 - Vector2.one;
			_vfx.SetVector2("textureOffSet", _texturePosition);
		}
	}

	#endregion VFX

	#region Compute

	private Vector3 _smallMovementPosition;
	public Transform startPosition;
	public Transform abovePosition;
	private Vector3 _currentLargePosition;

	private void SetPosition(OSCMessage msg) {
		if (msg.ToVector3(out Vector3 s)) {
			_smallMovementPosition = s * 60.0f - Vector3.one * 30.0f;
			transform.position = _currentLargePosition + _smallMovementPosition;
		}
	}

	private void SetLargePosition(OSCMessage msg) {
		if (msg.ToFloat(out float f)) {
			_currentLargePosition = Vector3.Lerp(startPosition.position, abovePosition.position, f);
			transform.position = _currentLargePosition + _smallMovementPosition;
		}
	}

	private void SetRotation(OSCMessage msg) {
		if (msg.ToVector3(out Vector3 s)) {
			s = s * 360.0f - Vector3.one * 180.0f;
			transform.rotation = Quaternion.Euler(s[0], s[1], s[2]);
		}
	}

	private void SetForce(OSCMessage msg) {
		if (msg.ToVector3(out Vector3 s)) {
			_tOpts[0].globalForce.x = s.x * 2.0f - 1.0f;
			_tOpts[0].globalForce.y = s.y * 2.0f - 1.0f;
			_tOpts[0].globalForce.z = s.z * 2.0f - 1.0f;
		}
	}

	private void SetWidth(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _tOpts[0].width = f * 10.0f + 0.1f;
	}

	private void SetNoiseScale(OSCMessage msg) {
		if (msg.ToVector2(out Vector2 s)) {
			_tOpts[0].noiseScale.x = s.x;
			_tOpts[0].noiseScale.y = s.y;
		}
	}

	private void SetNoiseForce(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _tOpts[0].noiseStrength = f;
	}

	private void SetNoiseTimeScale(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _timeRate = f;
	}

	private void SetTensionForce(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _tOpts[0].tensionStrength = f * 35f;
	}

	private void SetDecay(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _tOpts[0].velocityDecay = f * 0.925f;
	}

	private void SetShape(OSCMessage msg) {
		if (msg.ToFloat(out float f)) _tOpts[0].shape = f;
	}

	#endregion Compute

	#endregion OSC Setters

	#region Compute Funcs

	private void Reallocate() {
		if (_tentaPoints != null)
			_tentaPoints.Release();

		_tentaPoints = new GraphicsBuffer(
			GraphicsBuffer.Target.Structured,
			pointsPerStrip * numStrips,
			Marshal.SizeOf(typeof(TentaPoint)));
		_tentaOptions = new GraphicsBuffer(
			GraphicsBuffer.Target.Structured,
			1,
			Marshal.SizeOf(typeof(TentaOptions)));

		_tentaPoints.SetData(new TentaPoint[pointsPerStrip * numStrips]);

		_tOpts[0].velocityDecay = 0.9f;
		_tOpts[0].tensionStrength = 30f;
		_tOpts[0].width = 1f;

		// _tOpts[0].pid.x = 1f / (Mathf.PI * 4f);
		// _tOpts[0].pid.y = 1f / ((2f * Mathf.PI * 4f) * (2f * Mathf.PI * 4f));
		// _tOpts[0].pid.z = 1f * 1f / (2f * Mathf.PI * 4f);
		_tOpts[0].shape = 0f;
		_tentaOptions.SetData(_tOpts);
	}

	public void Clear() {
		tentaComputeShader.Dispatch(_computeKernelInit, pointsPerStrip / 64, numStrips, 1);
	}

	private void ForEachKernel(Action<int> func) {
		func(_computeKernelInit);
		func(_computeKernelMain);
	}

	private void SetUpdateShaderParams() {
		_tOpts[0].numStrands = numStrips;
		_tOpts[0].timeStep = Mathf.Min(Time.deltaTime, 1 / 100f);

		Transform t = transform;
		_tOpts[0].origin = t.position;

		Quaternion r = t.rotation;
		_tOpts[0].rotation.x = r.x;
		_tOpts[0].rotation.y = r.y;
		_tOpts[0].rotation.z = r.z;
		_tOpts[0].rotation.w = r.w;

		_tOpts[0].time += Time.deltaTime * _timeRate;

		_tentaOptions.SetData(_tOpts);
	}

	private void SetAllShaderParams() {
		SetUpdateShaderParams();
		ForEachKernel(k => tentaComputeShader.SetBuffer(k, "tenta_points", _tentaPoints));
		ForEachKernel(k => tentaComputeShader.SetBuffer(k, "tenta_options", _tentaOptions));
	}

	private void StartTenta() {
		Reallocate();

		_vfx = GetComponent<VisualEffect>();
		_vfx.SetGraphicsBuffer(_vfxDataID, _tentaPoints);

		_computeKernelInit = tentaComputeShader.FindKernel("init");
		_computeKernelMain = tentaComputeShader.FindKernel("main");

		SetAllShaderParams();

		Clear();
	}

	#endregion

	#region Unity Functions

	private void Start() {
		StartOSCBind();
		StartTenta();
	}

	private void Update() {
		if (_tentaPoints == null) Start();
		SetUpdateShaderParams();

		tentaComputeShader.Dispatch(_computeKernelMain, pointsPerStrip / 64, numStrips, 1);
	}

	#endregion

	#region Dispose

	private void Release() {
		if (_tentaPoints != null)
			_tentaPoints.Release();
		_tentaPoints = null;
		if (_tentaOptions != null)
			_tentaOptions.Release();
		_tentaOptions = null;
	}

	private void OnDestroy() {
		Release();
	}

	private void OnDisable() {
		Release();
	}

	#endregion
}