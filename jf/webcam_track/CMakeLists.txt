cmake_minimum_required(VERSION 3.22)
project(webcam_track)

set(CMAKE_CXX_STANDARD 20)


find_package( OpenCV REQUIRED
        core
        imgproc
        features2d
        objdetect
        highgui
        imgcodecs
        cudaarithm
        cudafilters
        cudaimgproc
        cudafeatures2d
        cudaoptflow)

include_directories( ${OpenCV_INCLUDE_DIRS} oscpack_1_1_0 )

add_subdirectory(oscpack_1_1_0)

add_executable(webcam_track main.cpp)
target_link_libraries(webcam_track ${OpenCV_LIBS} oscpack)
