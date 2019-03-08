# CMake file for Depth/Color warper
# Author: zhu-ty
# E-mail: zhu.shadowk@gmail.com
#
message(
"
       
           ┌─┐       ┌─┐
        ┌──┘ ┴───────┘ ┴──┐
        │                 │
        │       ───       │
        │  ─┬┘       └┬─  │
        │                 │
        │       ─┴─       │
        │                 │
        └───┐         ┌───┘
            │         │
            │         │
            │         │
            │         └──────────────┐
            │                        │
            │                        ├─┐
            │                        ┌─┘    
            │                        │
            └─┐  ┐  ┌───────┬──┐  ┌──┘         
              │ ─┤ ─┤       │ ─┤ ─┤         
              └──┴──┘       └──┴──┘ 
                  神兽  保佑 
                  代码无BUG! 
  
")

cmake_minimum_required (VERSION 3.10)
set(name "ImageWarper")
project ( ${name} )

# cmake module
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

# c++ version
set (CMAKE_CXX_STANDARD 11)
set (WIN_LIB_PATH "E:/libs")

#opencv 
if ( WIN32 )
	set(OpenCV_DIR ${WIN_LIB_PATH}/OpenCV/x64/vc14/lib)
	set(OpenCV_CONFIG_PATH ${WIN_LIB_PATH}/OpenCV)
	#set(WIN_HEADER_PATH "${PROJECT_SOURCE_DIR}/winheadfile")
    #include_directories(${WIN_HEADER_PATH})
endif()

# OpenCV
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# Eigen3
if (WIN32)
	set(EIGEN_INCLUDE_DIR ${WIN_LIB_PATH}/Eigen/include/eigen3)
elseif ( UNIX )
		set(EIGEN_INCLUDE_DIR "/usr/local/include/eigen3")
endif()
include_directories(${EIGEN_INCLUDE_DIR})

# opengl
find_package(OpenGL REQUIRED)
# Ask the user to give the paths to GLFW, GLEW and GLM.
# On Linux this can be found automatically with pkg-config; 
# see http://stackoverflow.com/questions/6889264/cmake-flags-for-opengl-using-glew-and-glfw, for instance.
if ( WIN32 )
	set(GLFW_INCLUDE_PATH ${WIN_LIB_PATH}/OpenGL/include/GLFW)
	set(GLFW_LIBRARY ${WIN_LIB_PATH}/OpenGL/lib/glfw3.lib)
	set(GLEW_INCLUDE_PATH ${WIN_LIB_PATH}/OpenGL/include)
	set(GLEW_LIBRARY_DEBUG ${WIN_LIB_PATH}/OpenGL/lib/glew32d.lib)
	set(GLEW_LIBRARY_RELEASE ${WIN_LIB_PATH}/OpenGL/lib/glew32.lib)
	set(GLM_INCLUDE_PATH ${WIN_LIB_PATH}/OpenGL/include)
endif()
include_directories(
	${GLFW_INCLUDE_PATH}
	${GLEW_INCLUDE_PATH}
	${GLM_INCLUDE_PATH}
)

#cuda
find_package(CUDA)
set(CUDA_NVCC_FLAGS
    ${CUDA_NVCC_FLAGS}
#    -O3 
	-gencode=arch=compute_61,code=\"sm_61,compute_61\"
)

include_directories(
	${PROJECT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/OpenGLImageWarper
    ${PROJECT_SOURCE_DIR}/OpenGLImageWarper/common
)

set(WARPER_FILES
	OpenGLImageWarper/common/shader.hpp
	OpenGLImageWarper/common/shader.cpp
	OpenGLImageWarper/OpenGLImageWarper.h
	OpenGLImageWarper/OpenGLImageWarper.cpp
)

set(MY_FILES
	SKCommon.hpp
	main.cpp
)

cuda_add_executable(${name}
	${WARPER_FILES}
	${MY_FILES}
)

target_link_libraries(${name}
	${OPENGL_LIBRARY}
	${GLFW_LIBRARY}
	${GLEW_LIBRARY_DEBUG}
	${GLEW_LIBRARY_RELEASE}
	${OpenCV_LIBS}
	${CUDA_LIBRARY}
	cuda
	${CUDA_npp_LIBRARY} 
	${CUDA_nppc_LIBRARY} 
	${CUDA_nppicc_LIBRARY}
	${CUDA_nppicom_LIBRARY}
	${CUDA_nppidei_LIBRARY}
	${CUDA_nppif_LIBRARY}
	${CUDA_nppig_LIBRARY}
	${CUDA_nppim_LIBRARY}
	${CUDA_nppist_LIBRARY}
	${CUDA_nppisu_LIBRARY}
	${CUDA_nppitc_LIBRARY}
	${CUDA_npps_LIBRARY} 
)








