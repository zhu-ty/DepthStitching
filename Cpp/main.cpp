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
	if (argc >= 8)
	{
		SKCommon::warningOutput("Looks like you are using old input way to enter Warper, please confirm new way.");
		SKCommon::infoOutput("Input Sample: \n ./ImageWarper input.tiff mesh.yml 1920 1080 warped 0[0 = forward, 1 = backward]");
		return 0;
	}
	else if (argc < 7)
	{
		SKCommon::infoOutput("Input Sample: \n ./ImageWarper input.tiff mesh.yml 1920 1080 warped 0[0 = forward, 1 = backward]");
		return 0;
	}

	//input : inputimg,	meshfile,	owidth,	oheight,	outname,	way_s
	//input : 1,		2,			3,		4,			5,			6

	std::string inputimg = argv[1],
		meshfile = argv[2],
		owidth = argv[3],
		oheight = argv[4],
		outname = argv[5],
		way_s = argv[6];

	int w = atoi(owidth.c_str()), h = atoi(oheight.c_str());
	int way = atoi(way_s.c_str());
	cv::FileStorage fsm(meshfile, cv::FileStorage::READ);
	cv::Mat mesh_read;
	fsm["mesh"] >> mesh_read;
	fsm.release();
	gl::OpenGLImageWarper warper;
	warper.init(gl::OpenGLImageWarper::_defalutVertexShader, gl::OpenGLImageWarper::_defalutFragmentShader, gl::OpenGLImageWarper::ShaderLoadMode::Content);
	cv::Mat mesh_real = gl::OpenGLImageWarper::meshNoraml2Real(mesh_read, w, h);
	
	cv::Mat img = cv::imread(inputimg, cv::IMREAD_UNCHANGED);
	cv::Mat output;

	cv::Mat mask_origin(img.size(), CV_8U);
	mask_origin.setTo(cv::Scalar(255));
	cv::Mat mask;
	warper.warpSingle<unsigned char>(mask_origin, mask, cv::Size(w, h), mesh_real, way, GL_NEAREST);
	cv::imwrite(outname + std::string(".mask.png"), mask);


	if (1 + (img.type() >> CV_CN_SHIFT) == 3)
	{
		warper.warp(img, output, cv::Size(w, h), mesh_real, way);
		cv::imwrite(outname + ".png", output);
	}
	else if (1 + (img.type() >> CV_CN_SHIFT) == 1)
	{
		uchar depth = img.type() & CV_MAT_DEPTH_MASK;
		switch (depth) 
		{
			case CV_8U:  
			{
				warper.warpSingle<unsigned char>(img, output, cv::Size(w, h), mesh_real, way);
				SavePFMFile<unsigned char>(output, outname + std::string(".char.pfm"));
				cv::imwrite(outname, output);
				break;
			}
			case CV_16U:
			{
				warper.warpSingle<unsigned short>(img, output, cv::Size(w, h), mesh_real, way);
				SavePFMFile<unsigned short>(output, outname + std::string(".short.pfm"));
				cv::imwrite(outname, output);
				break;
			}
			case CV_32S:
			{
				warper.warpSingle<unsigned int>(img, output, cv::Size(w, h), mesh_real, way);
				SavePFMFile<unsigned int>(output, outname + std::string(".int.pfm"));
				break;
			}
			case CV_32F:
			{
				warper.warpSingle<float>(img, output, cv::Size(w, h), mesh_real, way, GL_NEAREST);
				SavePFMFile<float>(output, outname + std::string(".float.pfm"));
				break;
			}
			default:
			{
				SKCommon::errorOutput("Only Single Channle 8bit 16bit 32bitInt or 32bitFloat supported");
				return -1;
			}
		}
		
	}
	else
	{
		SKCommon::errorOutput("Only Single Channle or 3 channle color supported");
		return -2;
	}
	


    return 0;
}