/*
 * dma_intr.h
 *
 *  Created on: 2019��10��16��
 *      Author: Administrator
 */

#ifndef SRC_DMA_INTR_H_
#define SRC_DMA_INTR_H_

#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xscugic.h"
#include "ad7606_sample.h"

/************************** Constant Definitions *****************************/
/*
 * Device hardware build related constants.
 */
#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#define MEM_BASE_ADDR		0x10000000
#define AD7606_BASE        XPAR_AD7606_SAMPLE_0_S00_AXI_BASEADDR


#define RX_INTR_ID		XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR
#define TX_INTR_ID		XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR


#define REG0_OFFSET     AD7606_SAMPLE_S00_AXI_SLV_REG0_OFFSET
#define REG1_OFFSET     AD7606_SAMPLE_S00_AXI_SLV_REG1_OFFSET
#define REG2_OFFSET     AD7606_SAMPLE_S00_AXI_SLV_REG2_OFFSET
#define REG3_OFFSET     AD7606_SAMPLE_S00_AXI_SLV_REG3_OFFSET

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)


/* Timeout loop counter for reset
 */
#define RESET_TIMEOUT_COUNTER	10000
/* test start value
 */
#define TEST_START_VALUE	0xC
/*
 * Buffer and Buffer Descriptor related constant definition
 */
#define MAX_PKT_LEN		1024//1k
/*
 * transfer times
 */
#define NUMBER_OF_TRANSFERS	100000

extern volatile int TxDone;
extern volatile int RxDone;
extern volatile int Error;

int  DMA_CheckData(int Length, u8 StartValue);
int  DMA_Setup_Intr_System(XScuGic * IntcInstancePtr,XAxiDma * AxiDmaPtr, u16 TxIntrId, u16 RxIntrId);
int  DMA_Intr_Enable(XScuGic * IntcInstancePtr,XAxiDma *DMAPtr);
int  DMA_Intr_Init(XAxiDma *DMAPtr,u32 DeviceId);



void DMA_DisableIntrSystem(XScuGic * IntcInstancePtr,u16 TxIntrId, u16 RxIntrId);
#endif