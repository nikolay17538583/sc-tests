from typing import List

import mediapipe.python.solutions.face_mesh_connections as fmc
import numpy as np


def average_x_pos(landmarks, indexes) -> float:
    return sum(landmarks[i].x for i in indexes) / len(indexes)


def average_y_pos(landmarks, indexes) -> float:
    return sum(landmarks[i].y for i in indexes) / len(indexes)


def average_z_pos(landmarks, indexes) -> float:
    return sum(landmarks[i].z for i in indexes) / len(indexes)


def average_3d_pos(landmarks, indexes) -> List[float]:
    return [average_x_pos(landmarks, indexes),
            average_y_pos(landmarks, indexes),
            average_z_pos(landmarks, indexes)]


def get_scale_factor(landmarks, iris_distance: float = 6) -> float:
    def np_landmark(indexes) -> np.array:
        return np.array(average_3d_pos(landmarks, [e[0] for e in indexes]))

    return float(
        iris_distance / np.linalg.norm(np_landmark(fmc.FACEMESH_LEFT_EYE) - np_landmark(fmc.FACEMESH_RIGHT_EYE))
    )
