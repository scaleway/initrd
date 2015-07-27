#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main(int argc,char *argv[]) {
  int portno =        80;
  char *host =        "169.254.42.42";
  char *message_fmt = "PATCH /state HTTP/1.1\r\n\
User-Agent: scw-boot-tools/0.1.0\r\n\
Host: %s:%d\r\n\
Accept: */*\r\n\
Connection: closed\r\n\
Content-Type: application/json\n\
Content-Length: %d\r\n\r\n\
{\"state_detail\": \"%s\"}";

  struct timeval timeout;
  struct sockaddr_in serv_addr;
  int sockfd, bytes, sent, received, total, status_code, retries = 1;
  char message[1024], response[4096], status_code_str[4];

  if (argc < 2) {
    printf("usage: %s <STATE>\n  i.e: %s booted\n", argv[0], argv[0]);
    return 1;
  }

  sprintf(message, message_fmt, host, portno, strlen(argv[1]) + 20, argv[1]);
  //printf("Request:\n%s\n",message);

  timeout.tv_sec = 10;
  timeout.tv_usec = 0;

 retry:
  while (--retries > 0) {
    //printf("Retries: %d\n", retries);
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
      fprintf(stderr, "ERROR opening socket... ");
      goto retry;
    }

    if (setsockopt (sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout,
		    sizeof(timeout)) < 0) {
      fprintf(stderr, "ERROR setsockopt failed... ");
      goto retry;
    }
  
    if (setsockopt (sockfd, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout,
		    sizeof(timeout)) < 0) {
      fprintf(stderr, "ERROR setsockopt failed... ");
      goto retry;
    }
    
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(portno);
    serv_addr.sin_addr.s_addr = inet_addr(host);

    if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
      fprintf(stderr, "ERROR connecting... ");
      goto retry;
    }

    total = strlen(message);
    sent = 0;
    while (sent < total) {
      bytes = write(sockfd, message + sent, total - sent);
      if (bytes < 0) {
	fprintf(stderr, "ERROR writing message to socket... ");
	goto retry;
      }
      if (bytes == 0) {
	break;
      }
      sent += bytes;
    }

    memset(response, 0, sizeof(response));
    total = sizeof(response)-1;
    received = 0;
    while (received < total) {
      bytes = read(sockfd, response + received, total - received);
      if (bytes < 0) {
	fprintf(stderr, "ERROR reading response from socket... ");
	goto retry;
      }
      if (bytes == 0) {
	break;
      }
      received += bytes;
    }

    if (received == total) {
      fprintf(stderr, "ERROR storing complete response from socket... ");
      goto retry;
    }

    close(sockfd);

    // printf("Response:\n%s\n", response);
    memcpy(status_code_str, response + 9, 3);
    status_code_str[4] = 0;
    status_code = atoi(status_code_str);
    // printf("Status code: %d\n", status_code);
    if (status_code == 200) {
      return 0;
    }
  }
  return 1;
}
