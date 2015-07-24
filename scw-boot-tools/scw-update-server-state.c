#include <stdio.h>
#include <curl/curl.h>
 
int main(int argc, char **argv)
{
  CURL *curl;
  CURLcode res;
  char post_data[1024];

  if (argc < 2) {
    printf("usage: %s <STATE>\n  i.e: %s booted\n", argv[0], argv[0]);
    return 1;
  }

  curl_global_init(CURL_GLOBAL_ALL);
 
  curl = curl_easy_init();
  if(!curl) {
    goto panic;
  }

  sprintf(post_data, "state_detail=%s", argv[1]);

  curl_easy_setopt(curl, CURLOPT_URL, "http://127.0.0.1:3000/state");
  curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_data);
 
  res = curl_easy_perform(curl);
  if (res != CURLE_OK) {
    fprintf(stderr, "curl_easy_perform() failed: %s\n",
	    curl_easy_strerror(res));
  }
  
  curl_easy_cleanup(curl);

 panic:
  curl_global_cleanup();
  return 0;
}
