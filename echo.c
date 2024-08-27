/*
 * Copyright (C) 2009 - 2019 Xilinx, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 */

#include <stdio.h>
#include <string.h>

#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#endif

// Defines app port
static unsigned port = 7;

int transfer_data() {
	return 0;
}

void print_app_header()
{
#if (LWIP_IPV6==0)
	xil_printf("\n\r\n\r-----lwIP TCP epic_eth receiver ------\n\r");
#else
	xil_printf("\n\r\n\r-----lwIPv6 TCP epic_eth receiver------\n\r");
#endif
	xil_printf("TCP packets sent to port %d will be echoed back\n\r", port);
}

static int cur_x = 0;
static int cur_y = 0;
static int ip_addr = -1;
#define X_MIN 0
#define Y_MIN 0
#define X_MAX 200
#define Y_MAX 200
volatile unsigned int * data_to_draw = (unsigned int *)0xc00003ff;

void calculate_x_gcode(char dir, int dist)
{
	xil_printf("G1 ");
	if (dir == 'L')
	{
		cur_x -= dist;
		if (cur_x < X_MIN)
		{
			cur_x = X_MIN;
		}
		*data_to_draw = 0xFE000000;
	}
	else if(dir == 'R')
	{
		cur_x += dist;
		if (cur_x > X_MAX)
		{
			cur_x = X_MAX;
		}
		*data_to_draw = 0xDC000000;
	}

	*data_to_draw += ((dist << 16) + ip_addr);
	xil_printf("X%d\r\n", cur_x);
}

void calculate_y_gcode(char dir, int dist)
{
	xil_printf("G1 ");
	if (dir == 'U')
	{
		cur_y += dist;
		if (cur_y > Y_MAX)
		{
			cur_y = Y_MAX;
		}
		*data_to_draw = 0xBA000000;
	}
	else if(dir == 'D')
	{
		cur_y -= dist;
		if (cur_y < Y_MIN)
		{
			cur_y = Y_MIN;
		}
		*data_to_draw = 0x98000000;
	}
	*data_to_draw += ((dist << 16) + ip_addr);
	xil_printf("Y%d\r\n", cur_y);
}

void move_head(struct pbuf *p)
{
	u8_t *tempPtr;
	tempPtr = (u8_t *)p->payload;

	if(*(tempPtr) == 'L' || *(tempPtr) == 'R')
	{
		calculate_x_gcode(*(tempPtr), strtol(++tempPtr, NULL, 16));
	}
	else if(*(tempPtr) == 'D' || *(tempPtr) == 'U')
	{
		calculate_y_gcode(*(tempPtr), strtol(++tempPtr, NULL, 16));
	}
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
struct pbuf *p, err_t err)
{
	/* do not read the packet if we are not in ESTABLISHED state */
	if (!p) {
		tcp_close(tpcb);
		tcp_recv(tpcb, NULL);
		return ERR_OK;
	}
	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);
//	tempPtr = (u8_t *)p->payload;

	/* Print payload received from Ethernet DMA */
//	xil_printf("Received Packet. Length = %d \r\n ", p->len);

	/* echo back the payload */
	/* in this case, we assume that the payload is < TCP_SND_BUF */

//	err = tcp_write(tpcb, "Homing axes...\r\n", 15, 1);

	if(ip_addr == -1)
	{
		ip_addr = *data_to_draw;
	}
	move_head(p);

	/* This will be changed to respond with populated struct if Bryson wants so that there is a response to his ETH server*/
//	if (tcp_sndbuf(tpcb) > p->len) {
//		err = tcp_write(tpcb, p->payload, p->len, 1);
//	} else
//		xil_printf("no space in tcp_sndbuf\n\r");

	/* free the received pbuf */
	pbuf_free(p);
	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	return ERR_OK;
}


int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;

	/* create new TCP PCB structure */
	pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/* bind to specified @port */
	err = tcp_bind(pcb, IP_ANY_TYPE, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

//	xil_printf("TCP epic_eth server started @ port %d\n\r", port);
	xil_printf("G28\r\n");	// Homing code in GCODE
	xil_printf("G90\r\n");	// Sets static positioning mode
	xil_printf("G1 F1200\r\n");

	return 0;
}
