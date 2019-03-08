#include<iostream>
#include"SKCommon.hpp"
#include"OpenGLImageWarper.h"

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


int main(int argc, char* argv[]) 
{
	if (argc < 8)
	{
		SKCommon::infoOutput("Input Sample: \n ./ImageWarper vshader.glsl fshader.glsl input.tiff mesh.yml 1920 1080 warped.png");
		return 0;
	}

	//input : vshader, fshader, inputimg, meshfile, owidth, oheight, outname
	int w = atoi(argv[5]), h = atoi(argv[6]);
	cv::FileStorage fsm(argv[4], cv::FileStorage::READ);
	cv::Mat mesh_read;
	fsm["mesh"] >> mesh_read;
	fsm.release();
	gl::OpenGLImageWarper warper;
	warper.init(argv[1], argv[2]);
	cv::Mat mesh_real = gl::OpenGLImageWarper::meshNoraml2Real(mesh_read, w, h);
	
	cv::Mat img = cv::imread(argv[3], cv::IMREAD_UNCHANGED);
	cv::Mat output;

	cv::Mat mask_origin(img.size(), CV_8U);
	mask_origin.setTo(cv::Scalar(255));
	cv::Mat mask;
	warper.warpSingle<unsigned char>(mask_origin, mask, cv::Size(w, h), mesh_real);
	cv::imwrite(argv[7] + std::string(".mask.png"), mask);


	if (1 + (img.type() >> CV_CN_SHIFT) == 3)
	{
		warper.warp(img, output, cv::Size(w, h), mesh_real);
		cv::imwrite(argv[7], output);
	}
	else if (1 + (img.type() >> CV_CN_SHIFT) == 1)
	{
		uchar depth = img.type() & CV_MAT_DEPTH_MASK;
		switch (depth) 
		{
			case CV_8U:  
			{
				warper.warpSingle<unsigned char>(img, output, cv::Size(w, h), mesh_real);
				SavePFMFile<unsigned char>(output, argv[7] + std::string(".char.pfm"));
				break;
			}
			case CV_16U:
			{
				warper.warpSingle<unsigned short>(img, output, cv::Size(w, h), mesh_real);
				SavePFMFile<unsigned short>(output, argv[7] + std::string(".short.pfm"));
				break;
			}
			case CV_32S:
			{
				warper.warpSingle<unsigned int>(img, output, cv::Size(w, h), mesh_real);
				SavePFMFile<unsigned int>(output, argv[7] + std::string(".int.pfm"));
				break;
			}
			case CV_32F:
			{
				warper.warpSingle<float>(img, output, cv::Size(w, h), mesh_real);
				SavePFMFile<float>(output, argv[7] + std::string(".float.pfm"));
				break;
			}
			default:
			{
				SKCommon::errorOutput("Only Single Channle 8bit 16bit 32bitInt or 32bitFloat supported");
				return -1;
			}
		}
		cv::imwrite(argv[7], output);
	}
	else
	{
		SKCommon::errorOutput("Only Single Channle or 3 channle color supported");
		return -2;
	}
	


    return 0;
}