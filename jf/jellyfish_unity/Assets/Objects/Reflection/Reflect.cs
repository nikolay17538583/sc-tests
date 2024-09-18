using System;
using System.Data.SqlTypes;
using System.Runtime.InteropServices;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;


public class Reflect : OscSrcBase {

    [System.Serializable]
    struct ReflectionData {
    	public Vector2 centroid;
        public float lux;
    }

    public RenderTexture worldTexture;

	private int[] _kernelID;
    public ComputeShader shader;
    private ComputeBuffer _level1;
	private ComputeBuffer _level2;
	private ComputeBuffer _results;

	//private float[] _returnedArray;
    private float[] _returnedResults;
    private ReflectionData _validResults;

    private bool _keepProcessing = true;

    void Start(){

        FindKernels();
        AllocData();
		AssignData();
		
		StartAsyncGPUProcess();

		BindTransmit("/centroid", GetCentroid);
		BindTransmit("/luminance", GetLuminance);
    }

	private void OnDestroy() {
		_keepProcessing = false;
		_results.Release();
		_level1.Release();
		_level2.Release();
	}

#region Setup
    private void FindKernels() {
		_kernelID = new int[2];
		_kernelID[0] = shader.FindKernel("FirstPass");
		_kernelID[1] = shader.FindKernel("SecondPass");
    }

    private void AllocData(){
		_level1 = new ComputeBuffer(32 * 32, sizeof(float) * 3);
		_level2 = new ComputeBuffer(8 * 8, sizeof(float) * 3);
		
		//_returnedArray = new float[4];
		//_returnedArray = new float[8*8];
        _results = new ComputeBuffer(1,  sizeof(float) * 3);
        _validResults = new ReflectionData();
	}

	private void AssignData() {
		foreach(var k in _kernelID){
			shader.SetTexture(k, "incoming_texture", worldTexture);
			shader.SetBuffer(k, "lvl1", _level1);
			shader.SetBuffer(k, "lvl2", _level2);
			shader.SetBuffer(k, "result", _results);
		}
	}
	private bool _doingGPU = true;
	void Update() {
		if (!_doingGPU && _keepProcessing) {
			StartAsyncGPUProcess();
		}
	}
	

    private void StartAsyncGPUProcess() {
		_doingGPU = true;
			
		foreach (int id in _kernelID) 
			shader.Dispatch(id, 1, 1, 1);

		AsyncGPUReadback.Request(_level2, r => {
			if (r.done && !r.hasError) {
		 		float[] arr = r.GetData<float>().ToArray();
		        _validResults.centroid.x = 0.0f;
		        _validResults.centroid.y = 0.0f;
		        _validResults.lux = 0.0f;
		        for (int y = 0; y < 8; ++y) {
			        for (int x = 0; x < 8; ++x) {
				        var cenX = arr[x + (y * 8)];
				        var cenY = arr[x + (y * 8) + 1];
				        var lum = arr[x + (y * 8) + 2];

				        _validResults.lux += IsSafeOr(lum, 0.0f);
				        _validResults.centroid.x += IsSafeOr(cenX, 0.0f);
				        _validResults.centroid.y += IsSafeOr(cenY, 0.0f);
			        }
		        }

		        _validResults.centroid /= _validResults.lux;
				_validResults.lux /= 412.0f;
		        //_validResults.centroid = (_validResults.centroid * 2.0f) - Vector2.one;

		        _doingGPU = false;
			}
		});

		// AsyncGPUReadback.Request(_results, sizeof(float)*4, 0, r => {
		// 	if (r.done && !r.hasError) {
		// 		_returnedResults = r.GetData<float>().ToArray();
		// 		doingGPU = false;
		// 	}
		// });
    }
#endregion

#region Safe floats
    private static bool IsSafe(float v) {
		return !float.IsInfinity(v) && !float.IsNaN(v);
	}
    private static bool IsSafe(Vector2 v) {
		return IsSafe(v.x) && IsSafe(v.y);
	}
    private static float IsSafeOr(float v, float other) {
		return IsSafe(v) ? v : other;
	}
    private static Vector2 IsSafeOr(Vector2 v, Vector2 other) {
		return IsSafe(v) ? v : other;
	}
#endregion

#region OSC Getters

	public Vector2 GetCentroid() {
        return _validResults.centroid;
	}
	public float GetLuminance() {
		//return Mathf.Clamp(_validResults.lux / 20.0f, 0.0f, 1.0f);
		return _validResults.lux;

	}


#endregion

}






































