/*
 * timer_intr.h
 *
 *  Created on: 2019Äê10ÔÂ16ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_TIMER_INTR_H_
#define SRC_TIMER_INTR_H_
#include <stdio.h>
#include "xadcps.h"
#include "xil_types.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xscutimer.h"


extern volatile int usec;
extern  int time_flag;
//timer info
#define TIMER_DEVICE_ID     XPAR_XSCUTIMER_0_DEVICE_ID
#define TIMER_IRPT_INTR     XPAR_SCUTIMER_INTR

void Timer_start(XScuTimer *TimerPtr);
void Timer_Setup_Intr_System(XScuGic *GicInstancePtr,XScuTimer *TimerInstancePtr, u16 TimerIntrId);
int Timer_init(XScuTimer *TimerPtr,u32 Load_Value,u32 DeviceId);


#endif /* SRC_TIMER_INTR_H_ */
