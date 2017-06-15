#include "messages.h"

module pubSubC {
    uses{
        interface Boot;
        interface Receive;
        interface AMSend;
        interface Timer<Milli> as Timer1;
        interface SplitControl;
    }
}

implementation{
    
    my_sub_t[] tempSub;
    my_sub_t[] humSub;
    my_sub_t[] lumSub;
    
    
    
    
    event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t) {
	    
	    my_msg_t* mess = (my_msg_t*) payload
	    nx_uint8_t type = mess->msg_type
	    if (TOS_NODE_ID = BROKER) {
            if (type == CONNECT){
            
            }
            else if (type == SUBSCRIBE){
            
            }
            else if (type == PUBLISH){
            
            }
            else if (type == PUBACK){
            
            }
            else {
            
            }
	        
	        
	    }
	    else
	    {
	    
	    }
	    
	}

} 
	 
