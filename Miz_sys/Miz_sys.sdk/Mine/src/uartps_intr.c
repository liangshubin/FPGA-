#include "uartps_intr.h"

// UART��ʽ
XUartPsFormat uart_format =
{
	115200,
	//XUARTPS_DFT_BAUDRATE,   //Ĭ�ϲ����� 115200
	XUARTPS_FORMAT_8_BITS,
	XUARTPS_FORMAT_NO_PARITY,
	XUARTPS_FORMAT_1_STOP_BIT,
};

//--------------------------------------------------------------
//                     UART��ʼ������
//--------------------------------------------------------------
int Uart_Init(XUartPs* Uart_Ps, u16 DeviceId)
{
	int Status;
	XUartPs_Config *Config;

	/*  ��ʼ��UART�豸    */
	Config = XUartPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}
	Status = XUartPs_CfgInitialize(Uart_Ps, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*  UART�豸�Լ�  */
	Status = XUartPs_SelfTest(Uart_Ps);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*  ����UARTģʽ�����   */
	XUartPs_SetOperMode(Uart_Ps, XUARTPS_OPER_MODE_NORMAL); //����ģʽ
	XUartPs_SetDataFormat(Uart_Ps, &uart_format);    //����UART��ʽ

	return XST_SUCCESS;
}

//--------------------------------------------------------------
//                     UART���ݷ��ͺ���
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
