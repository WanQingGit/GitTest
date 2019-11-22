/*
 *  Created on: Nov 12, 2019
 *  Author: WanQing
 *  E-mail: 1109162935@qq.com
 */

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
static char buff[MAX_MSG_SIZE + 200];
char *ptr, *tail;
int cli_sockfd;/*客户端SOCKET */
int fd_init() {
	int addrlen;
	char *seraddr = "192.168.1.120";
	struct sockaddr_in ser_addr,/* 服务器的地址*/
	cli_addr;/* 客户端的地址*/
	ptr = buff;
	tail = ptr + MAX_MSG_SIZE;
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
static inline int sendinfo(char *msg) {
	return send(cli_sockfd, msg, strlen(msg), 0);/*发送数据*/
}
static inline int recvinfo() {
	return recv(cli_sockfd, buff, MAX_MSG_SIZE, 0); /* 接受数据*/
}
static inline void close_fd() {
	close(cli_sockfd);
	cli_sockfd = 0;
}
int main() {
	if (fd_init() == 0) {
		for (int i = 0; i < 2000; i++) {
			ptr += sprintf(ptr, "send info %d", i);
			*ptr = '\n';
			ptr++;
			if (ptr > tail) {
				sendinfo(buff);
				ptr = buff;
			}
		}
		if (ptr != buff)
			sendinfo(buff);
		close_fd();
	}
}
