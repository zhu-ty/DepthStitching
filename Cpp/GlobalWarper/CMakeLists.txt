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
set(name "GlobalWarper")
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
endif()
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

#cuda
find_package(CUDA)
set(CUDA_NVCC_FLAGS
    ${CUDA_NVCC_FLAGS}
#    -O3 
	-gencode=arch=compute_61,code=\"sm_61,compute_61\"
)
include_directories(
	${PROJECT_SOURCE_DIR}
)

file (GLOB this_h "./*.h")
file (GLOB this_hpp "./*.hpp")
file (GLOB this_cpp "./*.cpp")
file (GLOB this_c "./*.c")


set(MY_FILES
	${this_h}
	${this_hpp}
	${this_c}
	${this_cpp}
)

cuda_add_executable(${name}
	${MY_FILES}
	GWConfig.ini
)

target_link_libraries(${name}
	${OpenCV_LIBS}
	${CUDA_LIBRARY}
	cuda
)








