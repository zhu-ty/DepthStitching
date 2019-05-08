
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
	cv::Size sz;
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


int main(int argc, char* argv[]) 
{
	INIReader r("GWConfig.ini");
	std::vector<Global> data;
	data.resize(r.GetInteger("Common", "GlobalCount", 0));
	for (int i = 0; i < data.size(); i++)
	{
		data[i].color = cv::imread(r.Get(SKCommon::format("Global%d", i), "Image", "x.jpg"), cv::IMREAD_UNCHANGED);
		data[i].mask = cv::imread(r.Get(SKCommon::format("Global%d", i), "Mask", "x.png"), cv::IMREAD_UNCHANGED);
		std::string krFile = r.Get(SKCommon::format("Global%d", i), "KRFile", "x.yml");
		cv::FileStorage fs(krFile, cv::FileStorage::READ);
		fs["K"] >> data[i].K;
		fs["R"] >> data[i].R;
		cv::resize(data[i].mask, data[i].mask, data[i].color.size());
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
	w->setScale(data[0].K.at<float>(0,0));
	for (int i = 0; i < data.size(); i++)
	{
		data[i].corner = w->warp(data[i].color, data[i].K, data[i].R, cv::INTER_LINEAR, cv::BORDER_CONSTANT, data[i].wColor);
		w->warp(data[i].mask, data[i].K, data[i].R, cv::INTER_LINEAR, cv::BORDER_CONSTANT, data[i].wMask);
		data[i].sz = data[i].wColor.size();
	}
	blender_->prepare(getVecFromVecP(data), getVecFromVecS(data));
	for (int i = 0; i < data.size(); i++) {
		// feed to blender
		blender_->feed(data[i].wColor, data[i].wMask, data[i].corner);
	}
	cv::Mat result, resultM;
	blender_->blend(result, resultM);
	std::string oName = r.Get("Common", "Merged", "merged.png");
	cv::imwrite(oName, result);
	cv::imwrite(oName + ".mask.png", resultM);
    return 0;
}