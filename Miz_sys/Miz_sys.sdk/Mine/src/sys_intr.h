/*
 * sys_intr.h
 *
 *  Created on: 2019Äê10ÔÂ16ÈÕ
 *      Author: Administrator
 */

#ifndef SRC_SYS_INTR_H_
#define SRC_SYS_INTR_H_

#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xscugic.h"


#define INTC_DEVICE_ID          XPAR_SCUGIC_SINGLE_DEVICE_ID

int Init_Intr_System(XScuGic * IntcInstancePtr);
void setup_Intr_Exception(XScuGic * IntcInstancePtr);

void Setup_Intr_Exception(XScuGic * IntcInstancePtr);

#endif /* SRC_SYS_INTR_H_ */
