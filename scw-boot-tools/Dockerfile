FROM gcc:4.9
COPY . /app
WORKDIR /app
RUN make
CMD ["cat", "./scw-update-server-state"]
