using TMPro;
using UnityEngine;

public class fps : MonoBehaviour {
	private float deltaTime;
	private TMP_Text fpsText;

	private void Start() {
		fpsText = gameObject.GetComponent<TMP_Text>();
	}

	private void Update() {
		deltaTime += (Time.deltaTime - deltaTime) * 0.1f;
		float fps = 1.0f / deltaTime;
		fpsText.text = Mathf.Ceil(fps).ToString();
	}
}