from typing import NamedTuple

import cv2
import mediapipe as mp

import types_for_project as tp


def process_landmarks_loop(cap,
                           face_mesher: mp.solutions.face_mesh.FaceMesh,
                           landmark_relay: tp.LandmarkRelay,
                           video_processor: tp.VideoProcessor):
    while cap.isOpened():
        success, image = cap.read()

        if not success:
            continue

        image.flags.writeable = False
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results: NamedTuple = face_mesher.process(image)

        if results.multi_face_landmarks:
            landmark_relay(results.multi_face_landmarks[0].landmark)

            if video_processor(image, results.multi_face_landmarks):
                break


def process_landmarks(landmark_processor: tp.LandmarkRelay, video_processor: tp.VideoProcessor):
    camera = cv2.VideoCapture(0)

    try:
        with mp.solutions.face_mesh.FaceMesh(
                max_num_faces=1,
                refine_landmarks=True,
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5
        ) as face_mesh:
            process_landmarks_loop(camera, face_mesh, landmark_processor, video_processor)
            camera.release()

    except KeyboardInterrupt:
        camera.release();
