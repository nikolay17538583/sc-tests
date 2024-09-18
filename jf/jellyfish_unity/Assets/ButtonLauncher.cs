using System.Collections;
using extOSC;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ButtonLauncher : OscSinkBase {
	public TextMeshProUGUI text;
	private Button _button;
	private LaunchState _launchState = LaunchState.NotLaunched;

	private void Start() {
		_launchState = LaunchState.NotLaunched;
		_button = GetComponent<Button>();
		_button.onClick.AddListener(SendTrigger);

		BindReceiveGlobal("/launch_project/launching", _ => _launchState = LaunchState.Launching);
		BindReceiveGlobal("/launch_project/finished", _ => _launchState = LaunchState.Countdown);
		StartCoroutine(CountDown());
	}

	private void SendTrigger() {
		OSCMessage m = new("/launch_project", OSCValue.Bool(true));
		Manager.SendOneOff(m);
	}

	private IEnumerator CountDown() {
		yield return new WaitUntil(() => _launchState == LaunchState.Launching);
		text.fontStyle = FontStyles.Normal | FontStyles.Bold;
		text.text = "booting ...";
		yield return new WaitUntil(() => _launchState == LaunchState.Countdown);
		for (int x = 3; x != 0; --x) {
			text.text = x.ToString();
			yield return new WaitForSeconds(2f);
		}

		_button.gameObject.SetActive(false);
		yield return null;
	}

	private enum LaunchState {
		NotLaunched,
		Launching,
		Countdown
	}
}