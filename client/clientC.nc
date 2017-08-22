#include "messages.h"
#include "printf.h"
#include "Timer.h"

module clientC {
    uses{
        
        interface Boot;
        interface SplitControl;
        
        interface Receive as ReceivePub;
        interface Receive as ReceiveSimpleMsg;

        interface AMSend as SendSimpleMsg;
        interface AMSend as SendPub;
        interface AMSend as SendSub;

        interface Packet;
        
        interface Timer<TMilli>;
    }
}

implementation {
    
}