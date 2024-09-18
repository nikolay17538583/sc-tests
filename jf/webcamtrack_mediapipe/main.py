import sys

import data_extractors as dx
import data_extractors.positions as pos
from head_tracker_relay import HeadTrackerRelay
from landmark_processor import process_landmarks
from video_processor import HideVideo, ShowVideo

def main(show_video: bool, port: int = 65313):
    process_landmarks(
        landmark_processor=HeadTrackerRelay(
            ip="127.0.0.1",
            port=port,
            relative_info_gatherer=dx.RelativeInfoGatherer(),
            addr_func_pair=[
                # ("/webcam/head_tilt", dx.HeadTilt()),
                # ("/webcam/pos/lip/bot", pos.BottomLip()),
                # ("/webcam/pos/lip/top", pos.TopLip()),
                # ("/webcam/pos/eyebrow/left", pos.LeftEyebrow()),
                # ("/webcam/pos/eyebrow/right", pos.RightEyebrow()),
                # ("/webcam/pos/eye/left", pos.LeftEye()),
                # ("/webcam/pos/eye/right", pos.RightEye()),
                # ("/webcam/pos/nose", pos.Nose()),
                # ("/webcam/nod/state", dx.NodHeadTilt()),
                # ("/webcam/nod/eyebrows", dx.NodEyebrows()),
                ("/webcam/pos/forehead", pos.Forehead()),
                ("/webcam/nod/state", dx.NewNodder()),
            ]),
        video_processor=ShowVideo() if show_video else HideVideo()
    )


opts = [opt for opt in sys.argv[1:] if opt.startswith("-")]

if __name__ == "__main__":
    if '-h' in opts:
        print("""
        Help:
            -d : display video
        """)
    main(show_video='-d' in opts)
