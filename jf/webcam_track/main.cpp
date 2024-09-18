//#include <iostream>
#include <limits>
#include <chrono>
#include <optional>

#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>

//cuda
#include <opencv2/core/cuda.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/cudaoptflow.hpp>
#include <opencv2/cudaarithm.hpp>

#include "osc/OscOutboundPacketStream.h"
#include "ip/UdpSocket.h"
#include "ip/IpEndpointName.h"




struct Nod {
	std::tuple<float, bool> track_state(double v){
		triggered = false;
		auto now = std::chrono::high_resolution_clock::now();
		auto time_spent_here = std::chrono::duration_cast<std::chrono::milliseconds>(now - start_time_of_current_state).count() / 1000.0;
		switch (current_state){
			case 0: state0(v, time_spent_here); break;
			case 1: state1(v, time_spent_here); break;
			case 2: state2(v, time_spent_here); break;
			case 3: state3(v, time_spent_here); break;
			default: current_state = 0; break;
		}
		return {current_state / 4.0f, triggered};
	}
private:
	std::size_t current_state{0};
	bool triggered{false};
	double thresh = 6.0;
	decltype(std::chrono::high_resolution_clock::now()) start_time_of_current_state{std::chrono::high_resolution_clock::now()};
	void state0(double v, double t){
		const bool within_new_range = -thresh < v and v < thresh;
		const bool satisfied_this_time = 0.0 < t;
		if (within_new_range and satisfied_this_time)
			current_state = 1;
	}
	void state1(double v, double t){
		const bool within_new_range = thresh < v;
		const bool within_this_range = -thresh < v and v < thresh; // no real range
		const double min_time = 0.2;

		if (within_new_range and min_time < t)
			advance();
		else if (within_this_range)
			return;
		else
			reset_soft();
	}
	void state2(double v, double t){
		const bool within_new_range = -thresh < v and v < thresh;
		const bool within_this_range = v > thresh;
		const double min_time = 0.1;
		const double max_time = 0.8;

		if (within_new_range and min_time < t and t < max_time)
			advance();
		else if (within_this_range and  max_time > t)
			return;
		else
			reset();
	}
	void state3(double v, double t){
		const bool within_new_range =  v < -thresh;
		const bool within_this_range = -thresh < v and v < thresh;
		const double min_time = 0.1;
		const double max_time = 2.0;

		if (within_new_range and min_time < t and t < max_time)
			advance();
		else if (within_this_range and max_time > t)
			return;
		else
			reset();
	}
	void advance(){
		current_state += 1;
		start_time_of_current_state = std::chrono::high_resolution_clock::now();
		if (current_state >= 4){
			triggered = true;
			//std::cout << "TRIGGERED" << std::endl;
			current_state = 0;
		}
	};
	void reset(){
		current_state = 0;
		start_time_of_current_state = std::chrono::high_resolution_clock::now();
	};
	void reset_soft(){ current_state = 0; }
};

int main() {
	Nod sequence;

	auto webcam{cv::VideoCapture(0, cv::VideoCaptureAPIs::CAP_GSTREAMER)};

	if (!webcam.isOpened()) {
//		std::cerr << "Could not open webcam.\n";
		return 1;
	}

	//const double fps = webcam.get(cv::CAP_PROP_FPS);
	//std::cout << "web cam fps is: " << fps << "\n";

	cv::namedWindow("Webcam");

	cv::Mat frame;
	webcam >> frame;
	const auto get_cur_grey_frame = [&](auto frame){
		cv::cuda::GpuMat gpu_frame;
		cv::cuda::GpuMat grey;
		gpu_frame.upload(frame);

		cv::cuda::cvtColor(gpu_frame, grey, cv::COLOR_BGR2GRAY);
		return grey;
	};

	cv::cuda::GpuMat previous_frame = get_cur_grey_frame(frame);
	auto opt_flow = cv::cuda::FarnebackOpticalFlow::create(
			5, 0.5, true, 50, 5, 5, 1.1, 0);


	cv::cuda::GpuMat flow;
	cv::cuda::GpuMat flow_parts[2];
	cv::cuda::GpuMat mag, magn, theta;
	std::vector<cv::cuda::GpuMat> hsv_array(3);
	cv::cuda::GpuMat hsv, hsv_8u, bgr;

	cv::Mat drawmat, movement;


	IpEndpointName host("localhost", 7771);
	constexpr int buf_sz{1024};
	char buffer[buf_sz];
	UdpTransmitSocket socket{host};


	auto prev_t = std::chrono::high_resolution_clock::now();

	while (true){
		webcam >> frame;
		cv::cuda::GpuMat this_frame = get_cur_grey_frame(frame);

		opt_flow->calc(previous_frame, this_frame, flow);

		cv::cuda::split(flow, flow_parts);

		flow.download(movement);
		const auto v{cv::sum(movement) * 0.00001 };

		const double totalMovement = [&]{
			auto raw = std::sqrt( v[0] * v[0] + v[1] * v[1] );
			raw /= 20.0;
			raw += 0.5;
			return std::clamp(raw, 0.0, 1.0);
		}();

		const double len = std::sqrt(std::abs(v[1]) * 10) * ( std::signbit(v[1]) ? 1.0 : -1.0);

		/*
		const std::string text = std::to_string(len);
		const int fontFace = cv::FONT_HERSHEY_SCRIPT_SIMPLEX;
		const double fontScale = 1;
		const int thickness = 3;
		cv::Mat img(600, 800, CV_8UC3, cv::Scalar::all(0));
		int baseline=0;
		cv::Size textSize = cv::getTextSize(text, fontFace,
		                                    fontScale, thickness, &baseline);
		baseline += thickness;

		// center the text
		cv::Point textOrg((img.cols - textSize.width)/2,
		              (img.rows + textSize.height)/2);

		// draw the box
		cv::rectangle(img, textOrg + cv::Point(0, baseline),
		          textOrg + cv::Point(textSize.width, -textSize.height),
		          cv::Scalar(0,0,255));
		// ... and the baseline first
		cv::line(img, textOrg + cv::Point(0, thickness),
		     textOrg + cv::Point(textSize.width, thickness),
		     cv::Scalar(0, 0, 255));

		// then put the text itself
		cv::putText(frame, text, textOrg, fontFace, fontScale,
		        cv::Scalar::all(255), thickness, 8);
		 */

		cv::imshow("Webcam", frame);

		osc::OutboundPacketStream p2(buffer, buf_sz);
		const auto s = sequence.track_state(len);
		p2 << osc::BeginMessage("/webcam/nod/state") << static_cast<float>(std::get<0>(s)) << static_cast<float>(std::get<1>(s)) << osc::EndMessage;
		p2 << osc::BeginMessage("/webcam/movement") << totalMovement;
		socket.Send(p2.Data(), p2.Size());

		//if(std::get<1>(s))
		//	std::cout << "got a nod" << std::endl;

		previous_frame = this_frame;


		if (cv::waitKey(1) == 'q')
			break;
	}

	return 0;
}
