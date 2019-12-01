
#include "SKCommon.hpp"
#include "INIReader.h"
#include <opencv2/opencv.hpp>

template<typename T>
void SavePFMFile(cv::Mat& img, std::string filename)
{
	using namespace std;
	cv::Size szt = img.size();
	FILE *stream = fopen(filename.c_str(), "wb");
	if (stream == 0)
		cout << "WriteFile: could not open file" << endl;
	// write the header
	fprintf(stream, "Pf\n%d %d\n%f\n", szt.width, szt.height, (float)-1.0f);

	for (int y = szt.height - 1; y >= 0; --y)
		for (int x = 0; x < szt.width; ++x)
		{
			T tmp = img.at<T>(y, x);
			if ((int)fwrite(&tmp, sizeof(T), 1, stream) != 1)
				cout << "WriteFile: problem writing data" << endl;
		}
	fclose(stream);
}

struct Global
{
	cv::Mat color, mask, K, R;
	cv::Mat wColor, wMask;
	cv::Point corner;
	cv::Size originSize, sz;
};

std::vector<cv::Point> getVecFromVecP(std::vector<Global> &g)
{
	std::vector<cv::Point> ret;
	for (int i = 0; i < g.size(); i++)	ret.push_back(g[i].corner);
	return ret;
}

std::vector<cv::Size> getVecFromVecS(std::vector<Global> &g)
{
	std::vector<cv::Size> ret;
	for (int i = 0; i < g.size(); i++)	ret.push_back(g[i].sz);
	return ret;
}


int forward(INIReader &r)
{
	std::vector<Global> data;
	data.resize(r.GetInteger("Common", "GlobalCount", 0));
	for (int i = 0; i < data.size(); i++)
	{
		data[i].color = cv::imread(r.Get(SKCommon::format("Global%d", i), "Image", "x.jpg"), cv::IMREAD_UNCHANGED);
		cv::resize(data[i].color, data[i].color, cv::Size(2000, 1500));
		data[i].mask = cv::imread(r.Get(SKCommon::format("Global%d", i), "Mask", "x.png"), cv::IMREAD_UNCHANGED);
		std::string krFile = r.Get(SKCommon::format("Global%d", i), "KRFile", "x.yml");
		cv::FileStorage fs(krFile, cv::FileStorage::READ);
		fs["K"] >> data[i].K;
		fs["R"] >> data[i].R;
		data[i].originSize = data[i].color.size();
		cv::resize(data[i].mask, data[i].mask, data[i].originSize);
		data[i].K.convertTo(data[i].K, CV_32FC1);
		data[i].R.convertTo(data[i].R, CV_32FC1);
		data[i].K = data[i].K * ((data[i].color.cols / 2) / data[i].K.at<float>(0, 2));
		data[i].K.at<float>(2, 2) = 1;
	}
	if (data.size() == 0)
	{
		SKCommon::errorOutput("data.size() < 1!");
		return -1;
	}
	cv::Ptr<cv::detail::SphericalWarper> w = cv::makePtr<cv::detail::SphericalWarper>(false);
	std::shared_ptr<cv::detail::Blender> blender_ = std::make_shared<cv::detail::MultiBandBlender>(false);
	w->setScale(data[0].K.at<float>(0, 0));
	auto blured = [](cv::Mat &m, int k) -> void
	{
		cv::GaussianBlur(m, m, cv::Size(k, k),
			k, 0, cv::BORDER_CONSTANT);
		double _max_mask;
		cv::minMaxLoc(m, 0, &_max_mask);
		m = m * (255.0 / _max_mask);
	};
	for (int i = 0; i < data.size(); i++)
	{
		data[i].corner = w->warp(data[i].color, data[i].K, data[i].R, cv::INTER_LINEAR, cv::BORDER_CONSTANT, data[i].wColor);
		w->warp(data[i].mask, data[i].K, data[i].R, cv::INTER_LINEAR, cv::BORDER_CONSTANT, data[i].wMask);
		cv::erode(data[i].wMask, data[i].wMask, cv::getStructuringElement(cv::MorphShapes::MORPH_RECT, cv::Size(301, 301)), cv::Point(-1, -1), 1, cv::BORDER_CONSTANT);
		blured(data[i].wMask, 101);
		data[i].sz = data[i].wColor.size();
	}
	blender_->prepare(getVecFromVecP(data), getVecFromVecS(data));

	for (int i = 0; i < data.size(); i++)
	{
		blender_->feed(data[i].wColor, data[i].wMask, data[i].corner);
	}
	cv::Mat result, resultM;
	blender_->blend(result, resultM);

	//output
	std::string oName = r.Get("Common", "Merged", "merged.png");
	cv::imwrite(oName, result);
	cv::imwrite(oName + ".mask.png", resultM);
	cv::FileStorage fsOut(oName + ".param.xml", cv::FileStorage::WRITE);
	fsOut << "scale" << data[0].K.at<float>(0, 0);
	for (int i = 0; i < data.size(); i++)
	{
		fsOut << cv::format("ref%dCorner", i) << data[i].corner;
		fsOut << cv::format("ref%dSize", i) << data[i].sz;
		fsOut << cv::format("ref%dKt", i) << data[i].K;
		fsOut << cv::format("ref%dRt", i) << data[i].R;
		fsOut << cv::format("ref%dOriginSize", i) << data[i].originSize;
	}
	return 0;
}

#define BASE_BASE 99999999

int backward(INIReader &r)
{
	std::string oName = r.Get("Common", "Merged", "merged.png");
	cv::Mat result = cv::imread(oName, cv::IMREAD_UNCHANGED);
	cv::FileStorage fsIn(oName + ".param.xml", cv::FileStorage::READ);
	std::vector<Global> data;
	data.resize(r.GetInteger("Common", "GlobalCount", 0));
	int baseX = BASE_BASE, baseY = BASE_BASE;
	float scale = fsIn["scale"];
	for (int i = 0; i < data.size(); i++)
	{
		fsIn[cv::format("ref%dKt", i)] >> data[i].K;
		fsIn[cv::format("ref%dRt", i)] >> data[i].R;
		data[i].K.convertTo(data[i].K, CV_32FC1);
		data[i].R.convertTo(data[i].R, CV_32FC1);
		fsIn[cv::format("ref%dCorner", i)] >> data[i].corner;
		fsIn[cv::format("ref%dSize", i)] >> data[i].sz;
		fsIn[cv::format("ref%dOriginSize", i)] >> data[i].originSize;

		if (data[i].corner.x < baseX)
			baseX = data[i].corner.x;
		if (data[i].corner.y < baseY)
			baseY = data[i].corner.y;
	}
	cv::Ptr<cv::detail::SphericalWarper> w = cv::makePtr<cv::detail::SphericalWarper>(false);
	w->setScale(scale);
	for (int i = 0; i < data.size(); i++)
	{
		//cv::Mat refi;
		result(cv::Rect(data[i].corner.x - baseX, data[i].corner.y - baseY, data[i].sz.width, data[i].sz.height)).copyTo(data[i].wColor);
		w->warpBackward(data[i].wColor, data[i].K, data[i].R, cv::INTER_LINEAR, cv::BORDER_CONSTANT, data[i].originSize, data[i].color);
	}

	//output
	std::string dir = "warpedBack";
	SKCommon::mkdir(dir);
	for (int i = 0; i < data.size(); i++)
	{
		cv::imwrite(dir + "/" + r.Get(SKCommon::format("Global%d", i), "Image", "x.jpg"), data[i].color);
		if (data[i].color.type() == CV_32FC1)
		{
			SavePFMFile<float>(data[i].color, dir + "/" + r.Get(SKCommon::format("Global%d", i), "Image", "x.jpg") + ".float.pfm");
		}
	}

	return 0;
}


int main(int argc, char* argv[]) 
{
	INIReader r("GWConfig.ini");
	if (r.GetBoolean("Common", "Backward", false))
		return backward(r);
	else
		return forward(r);
}