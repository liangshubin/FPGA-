#include "uartps_intr.h"

// UART格式
XUartPsFormat uart_format =
{
	115200,
	//XUARTPS_DFT_BAUDRATE,   //默认波特率 115200
	XUARTPS_FORMAT_8_BITS,
	XUARTPS_FORMAT_NO_PARITY,
	XUARTPS_FORMAT_1_STOP_BIT,
};

//--------------------------------------------------------------
//                     UART初始化函数
//--------------------------------------------------------------
int Uart_Init(XUartPs* Uart_Ps, u16 DeviceId)
{
	int Status;
	XUartPs_Config *Config;

	/*  初始化UART设备    */
	Config = XUartPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}
	Status = XUartPs_CfgInitialize(Uart_Ps, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*  UART设备自检  */
	Status = XUartPs_SelfTest(Uart_Ps);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*  设置UART模式与参数   */
	XUartPs_SetOperMode(Uart_Ps, XUARTPS_OPER_MODE_NORMAL); //正常模式
	XUartPs_SetDataFormat(Uart_Ps, &uart_format);    //设置UART格式

	return XST_SUCCESS;
}

//--------------------------------------------------------------
//                     UART数据发送函数
//--------------------------------------------------------------
int Uart_Send(XUartPs* Uart_Ps, u8 *sendbuf, int length)
{
	int SentCount = 0;

	while (SentCount < length)
	{
		SentCount += XUartPs_Send(Uart_Ps, &sendbuf[SentCount], 1);
	}

	return SentCount;
}
