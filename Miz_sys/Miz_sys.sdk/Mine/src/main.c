


/*
 * main.c
 *
 *  Created on: 2019年10月16日
 *      Author: Administrator
 */



#include "uartps_intr.h"
#include "dma_intr.h"
#include "timer_intr.h"
#include "sys_intr.h"
#include "stdio.h"
//#include "xgpio.h"

static XScuGic Intc; //GIC
static  XAxiDma AxiDma;
static  XScuTimer Timer;//timer

volatile u32 RX_success;
volatile u32 TX_success;

volatile u32 RX_ready=1;
volatile u32 TX_ready=1;

//#define TIMER_LOAD_VALUE    166666665 //0.5S

#define TIMER_LOAD_VALUE    0x13D92D3F //1S

#define HITS_OF_EVENT_LEN 4
#define HITS_OF_EVENT_INTERVAL 0xfffffff
#define DMA_LEN 16

typedef struct {
	u32 ch;
	u32 ts;
} hit_t;

hit_t hits_of_event[HITS_OF_EVENT_LEN];
int hit_current;
u32 hit_slience_start_ts = 0;
u8 hits_of_event_ready;

XUartPs Uart_Ps;		/* The instance of the UART Driver */

int x = 0;
int Tries = NUMBER_OF_TRANSFERS;
int i;
int Index;
u8 *TxBufferPtr= (u8 *)TX_BUFFER_BASE;
u32 *RxBufferPtr=(u32 *)RX_BUFFER_BASE;

/********************************************************/
u8 SEND_LENGTH = 1;      //ADC发送的字节长度： 64*SEND_LENGTH
int GATE = 2000;		 //低门限值的设定  0.4v
int GATE_HIGH = 5200;    //高门限值设定    0.8v
int GLITCH_TIME = 50000;
u32 send_data[4];
u32  My_buffer[512] = {0};
u8  My_buffer_backup[512] = {0};
u8  start_flag [2] = {'*','*'};
u8  over_flag [2] = {'#','#'};
char Data_Updat_Flag = 0;
/********************************************************/
u32 channeldata[8]={0};
u8 *pchannel;
u32 *pchanneldata;
u8 Value=0;
float speed_tx;
float speed_rx;
//static XGpio Gpio;

//#define AXI_GPIO_DEV_ID	        XPAR_AXI_GPIO_0_DEVICE_ID
void hit_dma_to_hit_arr(hit_t *hits_arr, u32 *hits_dma_buff)
{
	u8 i = 0;

	for (i = 0; i < DMA_LEN/2; i++) {
		hits_arr[i].ch = hits_dma_buff[i * 2 + 1];
		hits_arr[i].ts = hits_dma_buff[i * 2] ;
	}
}

void bubbleSort(hit_t* hits_arr)
{
	int m, n,i, j;
	for (i = 0; i < DMA_LEN / 2 - 1; i++)
		for (j = 0; j < DMA_LEN / 2 - 1 - i; j++)
			if (hits_arr[j].ts > hits_arr[j + 1].ts)
			{
				m = hits_arr[j].ch;
				n= hits_arr[j].ts;
				hits_arr[j].ts  = hits_arr[j + 1].ts ;
				hits_arr[j].ch  = hits_arr[j + 1].ch ;
				hits_arr[j + 1].ch  = m;
				hits_arr[j + 1].ts  = n;
			}
}

u8 hits_filter_and_push_to_hits_event_arr(u32 *hits_dma_buff)
{
	u8 hits_of_event_ready = 0;
	hit_t hits_arr[DMA_LEN/2];
	int i, j;
	u8 hit_repeated;
	hit_current=0;

	hit_dma_to_hit_arr(hits_arr, hits_dma_buff);
	bubbleSort(hits_arr);
	for (i = 0; i < DMA_LEN/2; i++) {
		/*if (hits_arr[i].ts <= hit_slience_start_ts + HITS_SLICE_INTERVAL) {
			continue;
		}*/
		if (hit_current != 0)
		{
			// check whether channel of this hit is repeated in hits_of_event array
			hit_repeated = 0;
			for (j = 0; j < hit_current; j++) {
				if (hits_arr[i].ch == hits_of_event[j].ch) {
					hit_repeated = 1;
					break;
				}
			}

			if (hit_repeated) {
				hit_current = 0;
				i--;
				continue;
			}

			// check whether the buffered hits already expired
			if (hits_arr[i].ts - hit_slience_start_ts > HITS_OF_EVENT_INTERVAL) {
				hit_current = 0;
				i--;
				continue;
			}
			//当数据中出现时间戳重新归零的情况
			if (hits_arr[i].ts - hit_slience_start_ts < 0) {
				hit_current= 0;
				i--;
				continue;
			}
		}
		memcpy(&hits_of_event[hit_current], &hits_arr[i], sizeof(hit_t));
		hit_current++;
		hit_slience_start_ts = hits_of_event[0].ts;
		// prepare to position, empty the hits_of_event array and set slience time stamp
		if (hit_current == HITS_OF_EVENT_LEN) {
			hits_of_event_ready = 1;
			hit_current = 0;
			break;
		}
	}
	return hits_of_event_ready;
}


int axi_dma_test()
{
	int Status;
	TxDone = 0;
	RxDone = 0;
	Error = 0;

	/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
	 * is enabled
	 */
	Xil_DCacheFlushRange((u32)TxBufferPtr, MAX_PKT_LEN);
	Timer_start(&Timer);
	while(1)
	{
		if(RX_ready)
		{
		   RX_ready=0;
		   Status = XAxiDma_SimpleTransfer(&AxiDma,(u64)RxBufferPtr,
					(u32)(MAX_PKT_LEN), XAXIDMA_DEVICE_TO_DMA);

		   memcpy((void*)My_buffer,RxBufferPtr, 64*SEND_LENGTH);
		   hits_of_event_ready = hits_filter_and_push_to_hits_event_arr(My_buffer);

		   if (hits_of_event_ready) {
		  				   Uart_Send(&Uart_Ps, start_flag, 2);
		  				   Uart_Send(&Uart_Ps, hits_of_event, sizeof(hit_t) * HITS_OF_EVENT_LEN);
		  				   Uart_Send(&Uart_Ps, over_flag, 2);
		  			   }
		 }

	   /*****************************************************************************/
		   if (Status != XST_SUCCESS) {return XST_FAILURE;}

		if(RxDone)
		{
			//确保cache的数据都进入DDR
			Xil_DCacheInvalidateRange((u64)RxBufferPtr, MAX_PKT_LEN);
			RxDone=0;
			RX_ready=1;
			//RX_ready=0;
			RX_success++;
		}

	}


		if (Error)
		{
			xil_printf("Failed test transmit%s done, "
			"receive%s done\r\n", TxDone? "":" not",
							RxDone? "":" not");
			goto Done;
		}


	/* Disable TX and RX Ring interrupts and return success */
	DMA_DisableIntrSystem(&Intc, TX_INTR_ID, RX_INTR_ID);
Done:
	xil_printf("--- Exiting Test --- \r\n");

	return XST_SUCCESS;

}

int init_intr_sys()
{
	DMA_Intr_Init(&AxiDma,0);//initial interrupt system
	Timer_init(&Timer,TIMER_LOAD_VALUE,0);
	Init_Intr_System(&Intc); // initial DMA interrupt system
	Setup_Intr_Exception(&Intc);
	DMA_Setup_Intr_System(&Intc,&AxiDma,TX_INTR_ID,RX_INTR_ID);//setup dma interrpt system
	Timer_Setup_Intr_System(&Intc,&Timer,TIMER_IRPT_INTR);
	DMA_Intr_Enable(&Intc,&AxiDma);
	/*****************************************/
	Uart_Init(&Uart_Ps,UART_DEVICE_ID);
	//printf( "UART initial success\r\n");
	/*****************************************/

}

void ad7606_send_length(u32 adc_addr, u32 send_len)
{
	/* provide length to AD7606 */
	AD7606_SAMPLE_mWriteReg(adc_addr, REG0_OFFSET, send_len)  ;
}

void ad7606_gate(u32 adc_addr, u32 gate)
{
	/* provide length to AD7606 */
	AD7606_SAMPLE_mWriteReg(adc_addr, REG1_OFFSET, gate)  ;
}

void ad7606_glitch_time(u32 adc_addr, u32 glitch_time)
{
	/* provide length to AD7606 */
	AD7606_SAMPLE_mWriteReg(adc_addr, REG2_OFFSET, glitch_time)  ;
}

void ad7606_gate_high(u32 adc_addr, u32 gate_high)
{
	/* provide length to AD7606 */
	AD7606_SAMPLE_mWriteReg(adc_addr, REG3_OFFSET, gate_high)  ;
}

int main(void)
{
	init_intr_sys();
	/*设定门限值*/
	ad7606_gate(AD7606_BASE, GATE);
	ad7606_gate_high(AD7606_BASE,GATE_HIGH);
	/*ADC发送的字节长度：32*SEND_LENGTH*/
	ad7606_send_length(AD7606_BASE,SEND_LENGTH);
	ad7606_glitch_time(AD7606_BASE,GLITCH_TIME);
	axi_dma_test();

}






