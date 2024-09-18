using System;
using extOSC;
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;


public class OSCManager : MonoBehaviour {
	public int receivingPort = 12346;
	public int transmittingPort = 12347;
	public bool initWithDebug;
	
	private OSCReceiver _receiver;
	private OSCTransmitter _transmitter;
	
	private List<Tuple<string, Func<float>>> _transmitMapFloat;
	private List<Tuple<string, Func<UnityEngine.Vector2>>> _transmitMapVec2;
	private List<Tuple<string, Func<UnityEngine.Vector3>>> _transmitMapVec3;
    
	private void DefineReceiver() {
		var r = gameObject.GetComponent<OSCReceiver>();
		if (r != null) {
			_receiver = r;
			return;
		}
		_receiver = gameObject.AddComponent<OSCReceiver>();
		_receiver.LocalPort = receivingPort;
		_receiver.LocalHost = "localhost";
		if (initWithDebug)
			_receiver.Bind("/debug", DebugMsg);
	}

	private void DefineTransmitter() {
		var t = gameObject.GetComponent<OSCTransmitter>();
		if (t != null) {
			_transmitter = t;
			return;
		}
		_transmitter = gameObject.AddComponent<OSCTransmitter>();
		_transmitter.RemoteHost = "127.0.0.1";
		_transmitter.RemotePort = transmittingPort;
	}
    
	void Awake() {
		if (_receiver == null) DefineReceiver();
		if (_transmitter == null) DefineTransmitter();
		if (_transmitMapFloat == null) _transmitMapFloat = new List<Tuple<string, Func<float>>>();
		if(_transmitMapVec2 == null) _transmitMapVec2 = new List<Tuple<string, Func<UnityEngine.Vector2>>>();
		if(_transmitMapVec3 == null) _transmitMapVec3 = new List<Tuple<string, Func<UnityEngine.Vector3>>>();
	}

	void Start() {
		Awake();
	}

	public void SendOneOff(OSCMessage msg) {
		_transmitter.Send(msg);
	}
    
	void LateUpdate() {
		Awake();
		foreach (var transMap in _transmitMapFloat) {
			var message = new OSCMessage(transMap.Item1);
			message.AddValue(OSCValue.Float(transMap.Item2()));
			_transmitter.Send(message);
		}
		foreach (var transMap in _transmitMapVec2) {
			var message = new OSCMessage(transMap.Item1);
			var d = transMap.Item2();
			message.AddValue(OSCValue.Float(d.x));
			message.AddValue(OSCValue.Float(d.y));
			_transmitter.Send(message);
		}
		foreach (var transMap in _transmitMapVec3) {
			var message = new OSCMessage(transMap.Item1);
			var d = transMap.Item2();
			message.AddValue(OSCValue.Float(d.x));
			message.AddValue(OSCValue.Float(d.y));
			message.AddValue(OSCValue.Float(d.z));
			_transmitter.Send(message);
		}
	}

	public string BindToReceiver(string root, string address, UnityAction<OSCMessage> callback) {
		Awake();
		var safeAddress = address[0] != '/' ? "/" + address : address;
		var safeRoot = root[0] != '/' ? "/" + root : root;
		var addr = safeRoot + safeAddress;
		Debug.Log("bound to receiver : " + addr);
		_receiver.Bind(addr, callback);
		if (initWithDebug) 
			_receiver.Bind(addr, DebugMsg);
		return addr; 
	}
	public string BindToGlobal(string address, UnityAction<OSCMessage> callback) {
		Awake();
		var safeAddress = address[0] != '/' ? "/" + address : address;
		Debug.Log("bound to receiver : " + safeAddress);
		_receiver.Bind(safeAddress, callback);
		if (initWithDebug) 
			_receiver.Bind( safeAddress, DebugMsg);
		return safeAddress;
	}

	public void BindToTransmitter(string address, Func<float> getter) {
		Awake();
		Debug.Log("bound to transmitter: " + address);
		_transmitMapFloat.Add(new Tuple<string, Func<float>>(address, getter));
	}
    
	public void BindToTransmitter(string address, Func<UnityEngine.Vector2> getter) {
		Awake();
		Debug.Log("bound to transmitter: " + address);
		_transmitMapVec2.Add(new Tuple<string, Func<UnityEngine.Vector2>>(address, getter));
	}
    
	public void BindToTransmitter(string address, Func<UnityEngine.Vector3> getter) {
		Awake();
		Debug.Log("bound to transmitter: " + address);
		_transmitMapVec3.Add(new Tuple<string, Func<UnityEngine.Vector3>>(address, getter));
	}
    
	public void DebugMsg(OSCMessage message) {
		if (initWithDebug) Debug.Log(message);
	}
}