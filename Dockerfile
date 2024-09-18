FROM ubuntu:22.04 AS builder
# created base image as builder, this will be multistep docer

# install required dependencies 
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y git 

RUN apt-get install -y make \
                       g++ \
                       libblas-dev \
                       liblapack-dev \
                       libboost-all-dev \
                       cmake \
                       python3 \
                       python3-pip \
                       wget && \
                       pip3 install numpy && \
    rm -rf /var/lib/apt/lists/*

# Create opt/mopac directory opt is for optional softwares, good professional practice
# to install add on software in this directory
RUN mkdir -p /opt/mopac && \
             git clone https://github.com/openmopac/mopac.git /opt/mopac

# we run cmake from build directory just to keep the source mopac directory clean    
#RUN mkdir /opt/mopac/build && \
# Build the application

WORKDIR /opt/mopac/build
RUN cmake -DBUILD_SHARED_LIBS=ON .. && \
    make -j 4

# Set the entrypoint to MOPAC executable
#ENTRYPOINT ["/opt/mopac/build/mopac"]
   
# Reduce image size, by taking only the mopac executable
FROM ubuntu:22.04

#adding shared library dependencies as mopac could not find the libraries from stage 1
RUN apt-get update && \
    apt-get install -y libblas-dev \
                       liblapack-dev \
                       libgomp1 \
                       libboost-all-dev && \
    rm -rf /var/lib/apt/lists/*


# copy built executable, needed for input file
COPY --from=builder /opt/mopac/build/mopac /bin
COPY --from=builder /opt/mopac/build/libmopac.so.2 /bin

#COPY --from=builder /opt/mopac/build/libmopac.so /bin


ENV LD_LIBRARY_PATH=/bin:$LD_LIBRARY_PATH

RUN ldconfig
# run mopac executable on call
ENTRYPOINT ["/bin/mopac"]

# added this command to use this input file as the argument for the entrypoint just in case its not provided. 
CMD ["formic_acid.mop"]
