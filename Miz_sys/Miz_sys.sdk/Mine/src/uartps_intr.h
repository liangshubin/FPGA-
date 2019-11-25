#ifndef SRC_USER_UART_H_
#define SRC_USER_UART_H_

#include "xparameters.h"
#include "xuartps.h"
#include "xil_printf.h"
#include "sleep.h"

#define UART_DEVICE_ID                  XPAR_XUARTPS_0_DEVICE_ID


int Uart_Send(XUartPs* Uart_Ps, u8 *sendbuf, int length);
int Uart_Init(XUartPs* Uart_Ps, u16 DeviceId);

#endif /* SRC_USER_UART_H_ */
