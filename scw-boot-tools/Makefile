TARGET = scw-update-server-state
SRCS = scw-update-server-state.c


LDFLAGS = $(shell curl-config --static-libs --cflags) -ldl -static


all: scw-update-server-state


$(TARGET): $(SRCS)
	gcc $(SRCS) $(LDFLAGS) -o $@


clean:
	rm -f $(TARGET)


re: clean all
