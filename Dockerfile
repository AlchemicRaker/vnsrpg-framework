FROM gcc:9.1.0 as toolchain-build
RUN git clone https://github.com/cc65/cc65.git
WORKDIR /cc65
RUN git checkout tags/V2.17
RUN make && PREFIX=/opt/cc65 make install
ENV PATH /opt/cc65/bin:$PATH

WORKDIR /src
CMD ["make"]