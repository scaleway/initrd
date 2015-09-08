#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <sys/mman.h>
#include <math.h>
#include <getopt.h>
#include <errno.h>
#include <netinet/in.h>
#include <arpa/inet.h>


/*
 * GLOBAL PARAMETERS
 */

static const char   *g_host = "169.254.42.42";
static const char   *g_port = "80";


/*
 * FUNCTIONS TO DISPLAY THE ERRORS
 */

char
mf_print_infos(const char *file, int line, const char *fct) {
	dprintf(2, "\033[0;37m%s, line \033[1;33m%d: \033[1;37m%s()\n\033[1;31m->\t", file, line, fct);
	return (0);
}

size_t
mf_error(char nothing, size_t ret, const char *fmt, ...) {
	va_list		ap;

	va_start(ap, fmt);
    vdprintf(2, fmt, ap);
    dprintf(2, ".\033[0m\n");
	va_end(ap);
	(void)nothing;
	return (ret);
}

void
mf_infos(const char *funct, const char *infos, ...) {
	va_list		ap;

	va_start(ap, infos);
    dprintf(2, "\033[1;37m->\t%s(): \033[0;33m", funct);
    vdprintf(2, infos, ap);
    dprintf(2, ".\033[0m\n");
	va_end(ap);
}

#define D_PRINT_INFOS			mf_print_infos(__FILE__, __LINE__, __func__)
#define M_ERROR(ret, fmt, ...)	mf_error(D_PRINT_INFOS, ret, fmt, ##__VA_ARGS__)
#define M_INFOS(str_inf, ...)	mf_infos(__func__, str_inf, ##__VA_ARGS__)

void
sf_free(void **ptr) {
    if (*ptr != NULL) {
        free(*ptr);
        *ptr = NULL;
    }
}

char *
strnstr(const char *s, const char *find, size_t slen) {
	char c, sc;
	size_t len;

	if ((c = *find++) != '\0') {
		len = strlen(find);
		do {
			do {
				if ((sc = *s++) == '\0' || slen-- < 1)
					return (NULL);
			} while (sc != c);
			if (len > slen)
				return (NULL);
		} while (strncmp(s, find, len) != 0);
		s--;
	}
	return ((char *)s);
}

/*
 * REQUEST STRUCTURE
 */


typedef enum    e_method {
    e_met_get = 0,
    e_met_head,
    e_met_post,
    e_met_put,
    e_met_delete,
    e_met_trace,
    e_met_options,
    e_met_connect,
    e_met_patch,
    e_met_max
}               e_method;

static const char *sg_method_str[] = {
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "TRACE",
    "OPTIONS",
    "CONNECT",
    "PATCH"
};

typedef enum    e_request_elem {
    e_req_method = 0,
    e_req_user_agent,
    e_req_host,
    e_req_accept,
    e_req_connection,
    e_req_content_type,
    e_req_content_length,
    e_req_body,
    e_req_max
}               e_request_elem;

typedef struct  s_request {
    char        *v_str[e_req_max];
}               t_request;

#define D_REQUEST(funct)  f_request_##funct

/*
 * REQUEST METHODS
 */

bool
f_request_add_method(t_request *v_this, e_method type, const char *path) {
    size_t  length;

    if (type >= e_met_max) {
        return M_ERROR(false, "Out of range");
    }
    if (path == NULL || strcmp(path, "") == 0) {
        path = "/";
    }
    // <request> <space> <path> <space> <protocol> <\r\n\0>
    length = strlen(sg_method_str[type]) + 1 + strlen(path) + 1 + strlen("HTTP/1.1") + 3;
    sf_free((void **)&v_this->v_str[e_req_method]);
    if ((v_this->v_str[e_req_method] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_method], length, "%s %s HTTP/1.1\r\n", sg_method_str[type], path);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_method]);
    return (true);
}

bool
f_request_add_host(t_request *v_this, const char *host, const char *port) {
    size_t  length;

    // <Host:> <space> <host> <:> <port> <\r\n\0>
    length = 5 + 1 + strlen(host) + 1 + strlen(port) + 3;
    sf_free((void **)&v_this->v_str[e_req_host]);
    if ((v_this->v_str[e_req_host] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_host], length, "Host: %s:%s\r\n", host, port);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_host]);
    return (true);
}

bool
f_request_add_user_agent(t_request *v_this, const char *user_agent) {
    size_t  length;

    // <User-Agent:> <user_agent> <\r\n\0>
    length = 11 + 1 + strlen(user_agent) + 3;
    sf_free((void **)&v_this->v_str[e_req_user_agent]);
    if ((v_this->v_str[e_req_user_agent] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_user_agent], length, "User-Agent: %s\r\n", user_agent);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_user_agent]);
    return (true);
}

bool
f_request_add_accept(t_request *v_this, const char *accept) {
    size_t  length;

    // <Accept:> <accept> <\r\n\0>
    length = 7 + 1 + strlen(accept) + 3;
    sf_free((void **)&v_this->v_str[e_req_accept]);
    if ((v_this->v_str[e_req_accept] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_accept], length, "Accept: %s\r\n", accept);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_accept]);
    return (true);
}

bool
f_request_add_connection(t_request *v_this, const char *connection) {
    size_t  length;

    // <Connection:> <accept> <\r\n\0>
    length = 11 + 1 + strlen(connection) + 3;
    sf_free((void **)&v_this->v_str[e_req_connection]);
    if ((v_this->v_str[e_req_connection] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_connection], length, "Connection: %s\r\n", connection);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_connection]);
    return (true);
}

bool
f_request_add_content_type(t_request *v_this, const char *content_type) {
    size_t  length;

    // <Content-Type:> <content_type> <\r\n\0>
    length = 13 + 1 + strlen(content_type) + 3;
    sf_free((void **)&v_this->v_str[e_req_content_type]);
    if ((v_this->v_str[e_req_content_type] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_content_type], length, "Content-Type: %s\r\n", content_type);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_content_type]);
    return (true);
}

bool
_f_request_add_content_length(t_request *v_this, size_t len) {
    size_t  length;

    // <Content-Length:> <space> <len> <\r\n\0>
    length = 15 + 1 + (len == 0 ? 1 : (size_t)(floor(log10(len) + 1))) + 3;
    sf_free((void **)&v_this->v_str[e_req_content_length]);
    if ((v_this->v_str[e_req_content_length] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_content_length], length, "Content-Length: %zd\r\n", len);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_content_length]);
    return (true);
}

bool
f_request_add_body(t_request *v_this, const char *body) {
    size_t  length;

    length = strlen(body) + 1;
    if (_f_request_add_content_length(v_this, length - 1) == false) {
        return false;
    }
    sf_free((void **)&v_this->v_str[e_req_body]);
    if ((v_this->v_str[e_req_body] = malloc(length)) == NULL) {
        return (M_ERROR(false, "Bad alloc"));
    }
    snprintf(v_this->v_str[e_req_body], length, "%s", body);
    // dprintf(1, "[%s]\n", v_this->v_str[e_req_body]);
    return (true);
}

/*
 * Don't forget to free the value returned
 */
const char *
f_request_make_request(t_request *v_this) {
    size_t  i;
    size_t  length;
    char    *ret;
	size_t	last;

    i = 0;
	last = 0;
    length = 0;
    while (i < e_req_max) {
        if (v_this->v_str[i] != NULL) {
            length = length + strlen(v_this->v_str[i]);
			if (i < e_req_body) {
				last = i;
			}
        } else {
            // M_INFOS("%d is not set", i);
        }
        i = i + 1;
    }
    length = length + 3;
    if ((ret = malloc(length)) == NULL) {
        return ((const char *)M_ERROR(0, "Bad alloc"));
    }
    ret[0] = '\0';
    i = 0;
    while (i < e_req_max) {
        if (v_this->v_str[i] != NULL) {
            strncat(ret, v_this->v_str[i], length);
            length = length - strlen(v_this->v_str[i]);
        }
		if (i == last) {
			strncat(ret, "\r\n", 2);
			length = length - 2;
		}
        i = i + 1;
    }
    return (ret);
}

void
f_request_init(t_request *v_this) {
    memset(v_this, 0, sizeof(*v_this));
}

void
f_request_destroy(t_request *v_this) {
    size_t  i;

    i = 0;
    while (i < e_req_max) {
        sf_free((void **)&v_this->v_str[i]);
        i = i + 1;
    }
}

/*
 * BUFFER STRUCTURE
 */

typedef struct  s_buffer {
    char        *v_data;
    int         v_length;
    int         v_capacity;
}               t_buffer;

#define D_BUFFER(funct) f_buffer_##funct

/*
 * BUFFER METHODS
 */

void
f_buffer_init(t_buffer *v_this) {
    memset(v_this, 0, sizeof(*v_this));
}

bool
_f_buffer_realloc(t_buffer *v_this, int needded) {
    size_t  new_size;
    char    *tmp;

    new_size = needded + 4096;
    if ((tmp = realloc(v_this->v_data, new_size)) == NULL) {
        sf_free((void **)&v_this->v_data);
        return (M_ERROR(false, "Bad alloc"));
    }
    v_this->v_capacity = new_size;
    v_this->v_data = tmp;
    return (true);
}

bool
f_buffer_append(t_buffer *v_this, const char *data, int length) {
    if (v_this->v_length + length >= v_this->v_capacity && _f_buffer_realloc(v_this, v_this->v_length + length) == false) {
        return (false);
    }
    memcpy(v_this->v_data + v_this->v_length, data, length);
    v_this->v_length = v_this->v_length + length;
    return (true);
}

const char*
f_buffer_dup(t_buffer *v_this) {
    char *ret;

	if ((ret = malloc(v_this->v_length)) == NULL) {
		return ((const char *)M_ERROR(0, "Bad alloc"));
	}
	memcpy(ret, v_this->v_data, v_this->v_length);
    return (ret);
}

void
f_buffer_destroy(t_buffer *v_this) {
    sf_free((void **)&v_this->v_data);
    memset(v_this, 0, sizeof(*v_this));
}

void
f_buffer_clear(t_buffer *v_this) {
    D_BUFFER(destroy)(v_this);
}

/*
 * CLIENT STRUCTURE
 */

typedef struct  s_client {
    int         v_fd;
    t_buffer    v_recv;
    t_buffer    v_send;
}               t_client;

#define D_CLIENT(funct) f_client_##funct

/*
 * CLIENT METHODS
 */

bool
f_client_init(t_client *v_this, const char *host, const char *port) {
    struct sockaddr_in  serv_addr;
    size_t              retries;

    retries = 5;
    v_this->v_fd = -1;
    D_BUFFER(init)(&v_this->v_send);
    D_BUFFER(init)(&v_this->v_recv);
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(atoi(port));
    serv_addr.sin_addr.s_addr = inet_addr(host);
    while (retries > 0) {
        errno = 0;
        if ((v_this->v_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
            M_ERROR(false, "Unable to get a socket: %s", strerror(errno));
            goto retry;
        }
        if ((connect(v_this->v_fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr))) < 0) {
            close(v_this->v_fd);
            M_ERROR(false, "Unable to connect: %s", strerror(errno));
            goto retry;
        }
        return (true);
retry:
        sleep(5);
        retries = retries - 1;
    }
    return (false);
}

bool
f_client_add_data_from_request(t_client *v_this, t_request *req) {
    size_t      length;
    const char  *str;

    if ((str = D_REQUEST(make_request)(req)) == NULL) {
        return (false);
    }
    length = strlen(str);
    if (D_BUFFER(append)(&v_this->v_send, str, length) == false) {
        sf_free((void **)&str);
        return (false);
    }
    sf_free((void **)&str);
    return (true);
}

void
f_client_destroy(t_client *v_this) {
    D_BUFFER(destroy)(&v_this->v_recv);
    D_BUFFER(destroy)(&v_this->v_send);
    close(v_this->v_fd);
}

bool
f_client_send(t_client *v_this) {
    char            buff[4096];
    int             rselect;
    int             slength;
    fd_set          read;
    fd_set          write;
    struct timeval  timeout;
    int             retries;
    int             bytes;

    retries = 3;
    slength = 0;
    while (1) {
        FD_ZERO(&read);
        FD_ZERO(&write);
        FD_SET(v_this->v_fd, &read);
        if (v_this->v_send.v_length - slength > 0) {
            FD_SET(v_this->v_fd, &write);
        }
        timeout.tv_sec = 10;
        timeout.tv_usec = 0;
        if ((rselect = select(v_this->v_fd + 1, &read, &write, 0, &timeout)) == -1) {
            if (errno == EAGAIN || errno == EINTR) {
                continue ;
            }
            return (M_ERROR(false, "An error has occured: %s", strerror(errno)));
        }
        if (rselect == 0) {
            if (retries == 0) {
                return (M_ERROR(false, "Time out"));
            }
            retries = retries - 1;
        } else {
            if (FD_ISSET(v_this->v_fd, &read)) {
                errno = 0;
                if ((bytes = recv(v_this->v_fd, buff, sizeof(buff), MSG_NOSIGNAL)) == -1) {
                    return (M_ERROR(false, "Unable to recv data: %s", strerror(errno)));
                } else if (bytes > 0) {
                    if (D_BUFFER(append)(&v_this->v_recv, buff, bytes) == false) {
                        return (false);
                    }
                } else {
					v_this->v_recv.v_data[v_this->v_recv.v_length] = '\0';
					// dprintf(1, "<<< [%s]\n", buff);
                    break ;
                }
            } else if (FD_ISSET(v_this->v_fd, &write)) {
                errno = 0;
                if ((bytes = send(v_this->v_fd, v_this->v_send.v_data + slength, v_this->v_send.v_length - slength, MSG_NOSIGNAL)) == -1) {
                    return (M_ERROR(false, "Unable to send data: %s", strerror(errno)));
                } else if (bytes > 0) {
                    slength = slength + bytes;
                    if (v_this->v_send.v_length - slength < 0) {
                        return (M_ERROR(false, "An error has occured"));
                    }
                }
            } else {
                return (M_ERROR(false, "An error has occured"));
            }
        }
    }
    return (true);
}


/*
 * FONCTION TO HANDLE '-s'
 */

int
uf_get_statuscode(char *str, int length) {
	int		ret;
	char	tmp;

    if (length < 13) {
        return (M_ERROR(-1, "An error has occured"));
    }
    str = str + 9;
	tmp = str[4];
    str[4] = '\0';
    // dprintf(1, ">>> %d <<< \n", atoi(str));
    ret = atoi(str);
	str[4] = tmp;
	return (ret);
}

const char *
uf_get_body(char *str, int length) {
	char	*ret;

	ret = strnstr(str, "\r\n\r\n", length);
	if (ret == NULL) {
		return ((const char *)M_ERROR(0, "Unable to find the body"));
	}
	return (ret + 4);
}

int
uf_state(const char *argv) {
    t_request   request;
    t_client    client;
    size_t      length;
    char        *body;
    bool        ret;

    D_REQUEST(init)(&request);
    if (D_REQUEST(add_host)(&request, g_host, g_port) == false
        || D_REQUEST(add_user_agent)(&request, "scw-boot-tools/0.1.0") == false
        || D_REQUEST(add_accept)(&request, "*/*") == false
        || D_REQUEST(add_connection)(&request, "closed") == false) {
        D_REQUEST(destroy)(&request);
        return (1);
    }
    if (D_CLIENT(init)(&client, g_host, g_port) == false) {
        D_REQUEST(destroy)(&request);
        return (1);
    }
    // <argv> <{"state_detail": ""}> <\0>
    length = strlen(argv) + strlen("{\"state_detail\": \"\"}") + 1;
    if ((body = malloc(length)) == NULL) {
        D_CLIENT(destroy)(&client);
        return (M_ERROR(1, "Bad alloc"));
    }
    snprintf(body, length, "{\"state_detail\": \"%s\"}", argv);
    ret = (D_REQUEST(add_method)(&request, e_met_patch, "/state") == false
        || D_REQUEST(add_content_type)(&request, "application/json") == false
        || D_REQUEST(add_body)(&request, body) == false
        || D_CLIENT(add_data_from_request)(&client, &request) == false
        || D_CLIENT(send)(&client) == false
        || uf_get_statuscode(client.v_recv.v_data, client.v_recv.v_length) != 200);
    sf_free((void **)&body);
    D_CLIENT(destroy)(&client);
    D_REQUEST(destroy)(&request);
    return (ret == true);
}

/*
 * FONCTION TO HANDLE '-u'
 */

int
uf_userdata(const char *argv) {
    t_request   request;
    t_client    client;
    size_t      length;
    char        *path;
    bool        ret;
	e_method	method;
	const char	*tab_str[2] = {0, 0};
	int			i;
	char		*parse;
	int			status_code;

	i = 0;
	method = e_met_get;
	parse = (char *)argv;
	while ((tab_str[i] = strsep(&parse, "=")) != NULL && i < 2) {
		i = i + 1;
	}
	if (tab_str[0] != NULL && tab_str[1] != NULL) {
		if (tab_str[1][0] == '\0') {
			method = e_met_delete;
		} else {
			method = e_met_patch;
		}
	}
	length = strlen(argv) + strlen("/user_data/");
	if ((path = malloc(length)) == NULL) {
		return (M_ERROR(1, "Bad alloc"));
	}
	path[0] = '\0';
	strncat(path, "/user_data/", length);
	strncat(path, argv, length - strlen("/user_data/"));
    D_REQUEST(init)(&request);
    if (D_REQUEST(add_host)(&request, g_host, g_port) == false
        || D_REQUEST(add_user_agent)(&request, "scw-boot-tools/0.1.0") == false
        || D_REQUEST(add_connection)(&request, "closed") == false
        || D_REQUEST(add_content_type)(&request, "text/plain") == false
        || D_REQUEST(add_accept)(&request, "*/*") == false) {
		sf_free((void **)&path);
        D_REQUEST(destroy)(&request);
        return (1);
    }
    if (D_CLIENT(init)(&client, g_host, g_port) == false) {
		sf_free((void **)&path);
        D_REQUEST(destroy)(&request);
        return (1);
    }
	if (method == e_met_patch) {
		if (D_REQUEST(add_body)(&request, tab_str[1]) == false) {
			sf_free((void **)&path);
			D_REQUEST(destroy)(&request);
			return (1);
		}
	}
    ret = (D_REQUEST(add_method)(&request, method, path) == false
        || D_CLIENT(add_data_from_request)(&client, &request) == false
        || D_CLIENT(send)(&client) == false);
	if (ret == false) {
		status_code = uf_get_statuscode(client.v_recv.v_data, client.v_recv.v_length);
	}
	if (ret == false && status_code == 200) {
		dprintf(1, "%s\n", uf_get_body(client.v_recv.v_data, client.v_recv.v_length));
	}
	sf_free((void **)&path);
    D_CLIENT(destroy)(&client);
    D_REQUEST(destroy)(&request);
	if (status_code != 200 && status_code != 204) {
		dprintf(2, "REQUEST ERROR [%d]\n", status_code);
	}
    return (!(status_code == 200 || status_code == 204));
}

int
main(int ac, const char **av) {
    int                     ch;
    static struct option    long_options[] = {
                            {"state", required_argument, NULL, 's'},
                            {"userdata", required_argument, NULL, 'u'},
                            {0, 0, 0, 0}
                        };

    mlockall(MCL_CURRENT | MCL_FUTURE);
    while ((ch = getopt_long(ac, (char * const *)av, "s:u:", long_options, NULL)) != -1) {
        switch (ch) {
            case 's':
                return (uf_state(optarg));
            case 'u':
                return (uf_userdata(optarg));
        }
    }
    dprintf(2, "Usage: %s [ OPTIONS ] params\n   -s STATE\n   -u KEY=VALUE\n", av[0]);
    return (1);
}
