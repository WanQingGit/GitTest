/*
 * cmodule.c
 *
 *  Created on: 2019年11月11日
 *      Author: WanQing


 aarch64-linux-android-clang -fPIC -DANDROID -ffunction-sections -fdata-sections -Wall -Os -pipe -g3 cmodule.c -o libcmodule.so -L. -lfrida-gum   -Wl,--export-dynamic -fuse-ld=gold -Wl,--icf=all,--gc-sections,-z,noexecstack,-z,relro,-z,now


 aarch64-linux-android-clang -fPIC -shared -DANDROID  -pipe -g3 cmodule.c -o libcmodule.so -L. -lfrida-gum
 */

#include "frida-gum.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <errno.h>

#define MAX_MSG_SIZE 4096
#define SERVER_PORT  6999
static char buff[MAX_MSG_SIZE];
int cli_sockfd = 0;/*客户端SOCKET */
char *seraddr = "192.168.1.120";
static inline void close_fd() {
	close(cli_sockfd);
	cli_sockfd = 0;
}
static inline int sendinfo(char *msg, n) {
	return send(cli_sockfd, msg, n, 0);/*发送数据*/
}
static inline int recvinfo() {
	return recv(cli_sockfd, buff, MAX_MSG_SIZE, 0); /* 接受数据*/
}
int fd_init() {
	if (cli_sockfd != 0)
		close_fd();
	int addrlen;
	struct sockaddr_in ser_addr,/* 服务器的地址*/
	cli_addr;/* 客户端的地址*/
	cli_sockfd = socket(AF_INET, SOCK_STREAM, 0);/*创建连接的SOCKET */
	if (cli_sockfd < 0) {/*创建失败 */
		fprintf(stderr, "socker Error:%s\n", strerror(errno));
		return -1;
	}
	/* 初始化客户端地址*/
	addrlen = sizeof(struct sockaddr_in);
	memset(&ser_addr, 0, addrlen);
	cli_addr.sin_family = AF_INET;
	cli_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	cli_addr.sin_port = 0;
	if (bind(cli_sockfd, (struct sockaddr*) &cli_addr, addrlen) < 0) {
		/*绑定失败 */
		fprintf(stderr, "Bind Error:%s\n", strerror(errno));
		return 1;
	}
	/* 初始化服务器地址*/
	addrlen = sizeof(struct sockaddr_in);
	memset(&ser_addr, 0, addrlen);
	ser_addr.sin_family = AF_INET;
	ser_addr.sin_addr.s_addr = inet_addr(seraddr);
	ser_addr.sin_port = htons(SERVER_PORT);
	if (connect(cli_sockfd, (struct sockaddr*) &ser_addr, addrlen) != 0)/*请求连接*/
	{
		/*连接失败 */
		fprintf(stderr, "Connect Error:%s\n", strerror(errno));
		return 2;
	}
	return 0;
}

//static void log(const gchar * format, ...);

float *ptr;
float var;

float monitor(float *addr) {
	if (fd_init() == 0) {
		ptr = addr;
		var = *addr;
		int n = sprintf(buff, "addr: %llX ,var:%f", addr, var);
		sendinfo(buff, n);
		return var;
	}
	return 8.8888;
}
//int main() {
//	return 0;
//}
//int testfn() {
//	return 1;
//}
void onEnter(GumInvocationContext * ic) {
//	const char * path;
//	path = gum_invocation_context_get_nth_argument(ic, 0);
//	log("open() path=\"%s\"", path);
	char buff[20];
	if (*ptr != var) {
		int n = sprintf(buff, "1 %#llx\n", ic->function);
		sendinfo(buff, n);
		var = *ptr;
	}
}

void onLeave(GumInvocationContext * ic) {
	if (*ptr != var) {
		char buff[20];
		int n = sprintf(buff, "2 %#llx\n", ic->function);
		buff[n] = '\n';
		sendinfo(buff, n);
		var = *ptr;
	}
//	int fd;
//	fd = (int) gum_invocation_context_get_return_value(ic);
//	log("=> fd=%d", fd);
}

