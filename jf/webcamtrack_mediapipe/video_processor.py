import cv2
import mediapipe as mp

import types_for_project as tp

mp_face_mesh = mp.solutions.face_mesh
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles


class VideoProcessor:
    def __call__(self, image, landmarks: tp.Landmarks) -> bool:
        pass


class ShowVideo(VideoProcessor):
    def __init__(self):
        self.drawing_spec = mp_drawing.DrawingSpec(thickness=1, circle_radius=1)

    def __call__(self, image: tp.CVImage, landmarks: tp.Landmarks) -> bool:
        image.flags.writeable = True

        for face_landmarks in landmarks:
            mp_drawing.draw_landmarks(
                image=image,
                landmark_list=face_landmarks,
                connections=mp_face_mesh.FACEMESH_TESSELATION,
                connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_tesselation_style()
            )
            mp_drawing.draw_landmarks(
                image=image,
                landmark_list=face_landmarks,
                connections=mp_face_mesh.FACEMESH_CONTOURS,
                connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_contours_style()
            )
            mp_drawing.draw_landmarks(
                image=image,
                landmark_list=face_landmarks,
                connections=mp_face_mesh.FACEMESH_IRISES,
                connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_iris_connections_style()
            )

        cv2.imshow('MediaPipe Face Mesh', cv2.flip(image, 1))
        return cv2.waitKey(1) & 0xFF == 27


class HideVideo(VideoProcessor):
    pass
