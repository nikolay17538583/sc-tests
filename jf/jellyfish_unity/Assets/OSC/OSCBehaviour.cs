using System;
using System.Collections.Generic;
using extOSC;
using UnityEditor;
using UnityEngine.Events;
using UnityEngine;

public class OscPortBase : MonoBehaviour {
    protected static OSCManager Manager;
    
    protected void SetManager() {
        if (Manager == null)
            Manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
    }
}

public class OscSinkBase : OscPortBase {
    protected List<string> BoundAddresses;

    protected void BindReceive(string address, UnityAction<OSCMessage> action) {
        SetManager();
        var a = Manager.BindToReceiver("/" + gameObject.name, address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    protected void BindReceiveGlobal(string address, UnityAction<OSCMessage> action) {
        SetManager();
        var a = Manager.BindToGlobal(address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
}

public class OscSrcBase : OscPortBase {
    protected void BindTransmit(string address, Func<float> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector2> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector3> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
}


public class OscSinkAndSrcBase : OscPortBase {
    protected List<string> BoundAddresses;
    
    protected void BindReceive(string address, UnityAction<OSCMessage> action) {
        SetManager();
        var a = Manager.BindToReceiver("/" + gameObject.name, address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    protected void BindReceiveGlobal(string address, UnityAction<OSCMessage> action) {
        SetManager();
        var a =Manager.BindToGlobal(address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    
    protected void BindTransmit(string address, Func<float> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector2> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector3> getter) {
        SetManager();
        Manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
}
