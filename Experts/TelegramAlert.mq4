//+------------------------------------------------------------------+
//|                                          TelegramSignalAlert.mq4 |
//|                                              Olorunishola Falana |
//|                                         sholafalana777@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Olorunishola Falana"
#property link      "sholafalana777@gmail.com"
#property version   "1.00"
#property strict
#include <Telegram.mqh>

//--- input parameters
input string InpChannelName="@mychannelname";//Channel Name
input string InpToken="insert telegram bot API here";//Token
extern string mySigalname = "Enter my signal name";

//--- global variables
CCustomBot bot;
int macd_handle;
datetime time_signal=0;
bool checked;

 bool AlertonTelegram = true;
 bool MobileNotification = false;
 bool EmailNotification = false;

extern bool alert_orderclosed = true;
extern bool alert_Pendingfilled = true;
extern bool alert_new_pending = true;
extern bool alert_new_order = true;
extern bool alert_pending_deleted = true;




int totalord,totalpnd,totalopn;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
   
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
  void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_KEYDOWN && 
      lparam=='Q')
     {
         
         bot.SendMessage(InpChannelName,"ee\nAt:100\nDDDD");
     }
  }
    
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+

int start()
  {
 time_signal=0;

   bot.Token(InpToken);
    if(!checked)
     {
      if(StringLen(InpChannelName)==0)
        {
         Print("Error: Channel name is empty");
         Sleep(10000);
         return (0);
        }

      int result=bot.GetMe();
      if(result==0)
        {
         Print("Bot name: ",bot.Name());
         checked=true;
        }
      else
        {
         Print("Error: ",GetErrorDescription(result));
         Sleep(10000);
         return(0);
        }
     }
  
  
string msg, msgbuy, msgsell, msgclos,msgfilled,msgdel,action1,action2,action3,msgpend,action4;


  int tmp = OrdersTotal();
      
  if (tmp < totalord ){    
    // last closed order fixed
   int last_trade= HistoryTotal();
   if(last_trade>0)
   {
       if(OrderSelect(last_trade-1,SELECT_BY_POS,MODE_HISTORY)==true)     {
            if ((OrderType()==OP_BUY) || (OrderType()==OP_SELL) ){
            string action1 = " Order Closed";
                 msgclos =StringFormat("Name: %s\nSymbol: %s\nPrice: %s\nAction: %s",mySigalname,OrderSymbol(),DoubleToString(OrderClosePrice(), 5),action1);
            
                msg= StringConcatenate(TypeMnem(OrderType())  ," Order closed : "," ", OrderSymbol()," "   ,OrderLots() , " Lot profit ",OrderProfit());
                if(alert_orderclosed){  
                     if(MobileNotification){SendNotification(msgclos);}                
                     if(EmailNotification){SendMail("Order changes Notification",msgclos);}
                     if(AlertonTelegram){ bot.SendMessage(InpChannelName,msgclos);}
                  }
                  
                  totalord = tmp;
                  return(0);
                                   
                  
            }        
        
        }
   }
  
  }
  

  // send new order alert
  int lastOpenTime = 0;  
  int tmp_pnd,temp_opn;
  int ord_type;
   for(int i = (OrdersTotal()-1); i >= 0; i --)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);      
      int curOpenTime = OrderOpenTime();      
      if(curOpenTime > lastOpenTime)
      {
         lastOpenTime = curOpenTime; 
         ord_type = OrderType();
     msgsell=StringFormat("Name: %s\nSymbol: %s\nType: Sell\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",
                                 mySigalname,OrderSymbol(),
                                 DoubleToString(OrderOpenPrice(),_Digits),
                                 TimeToString(OrderOpenTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits));  
         
            
    msgbuy =StringFormat("Name: %s\nSymbol: %s\nType: Buy\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                                 OrderSymbol(),
                                 DoubleToString(OrderOpenPrice(),_Digits),
                                 TimeToString(OrderOpenTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits)); 
       //  msg  = StringConcatenate("New ", TypeMnem(ord_type) ," Order   " , OrderSymbol()," "   ,OrderLots() , " Lot  @", OrderOpenPrice());
       }
        // if(cmd!=OP_BUY && cmd!=OP_SELL)
        if ((OrderType()==OP_BUY) || (OrderType()==OP_SELL) ){temp_opn=temp_opn + 1;}else{tmp_pnd =tmp_pnd +1 ;}
   }   
    if (tmp > totalord ){
   if ((ord_type==OP_BUY)  ){
   
               if(alert_new_order){
                if(MobileNotification){SendNotification(msgbuy);}                
                if(EmailNotification){SendMail("Order changes Notification",msgbuy);}
                if(AlertonTelegram){bot.SendMessage(InpChannelName,msgbuy);}
               }
           }     
           if((ord_type==OP_SELL)) {
            if(alert_new_order){
                if(MobileNotification){SendNotification(msgsell);}                
                if(EmailNotification){SendMail("Order changes Notification",msgsell);}
                if(AlertonTelegram){bot.SendMessage(InpChannelName,msgsell);}
               }
           
           }    
      
    }  
     








//-----------------------
if(tmp_pnd != totalpnd){
     //pending filled or deleted
      if(tmp_pnd < totalpnd){ 
          if(totalopn < temp_opn){
                if(alert_Pendingfilled){   
                  msg="Pending  Filled";
                   action2 = "Pending  Filled";
                   msgfilled =StringFormat("Name: %s \nSymbol: %s\nAction: %s",mySigalname,OrderSymbol(),action2); 
                  if(MobileNotification){SendNotification(msgfilled);}                
                  if(EmailNotification){SendMail("Order changes Notification",msgfilled);}
                  if(AlertonTelegram){bot.SendMessage(InpChannelName,msgfilled);}
                  }
          }
          else{msg="Pending  Deleted";
          action3 = "Pending  Deleted ";
                   msgdel =StringFormat("Name: %s\nSymbol: %s\nAction: %s",mySigalname,OrderSymbol(),action3); }
                if(alert_pending_deleted){
                  if(MobileNotification){SendNotification(msgdel);}                
                  if(EmailNotification){SendMail("Order changes Notification",msgdel);}
                  if(AlertonTelegram){bot.SendMessage(InpChannelName,msgdel);}
                }
      }
      
      // new pending placed
       if(tmp_pnd > totalpnd){ 
              if(alert_new_pending){
                  msg="New Pending order";
                  action4 = "New Pending order ";
                   msgpend =StringFormat("Name: %s\nSymbol: %s\nAction: %s",mySigalname,OrderSymbol(),action4); 
                  if(MobileNotification){SendNotification(msgpend);}                
                  if(EmailNotification){SendMail("Order changes Notification",msgpend);}
                  if(AlertonTelegram){bot.SendMessage(InpChannelName,msgpend);}
                 }
       
       }
      
   
   
}      



//-------------------------

 totalpnd=tmp_pnd;
 totalopn=temp_opn;
 totalord = tmp;
 //  }  // end of total ord change

   return(0);
  }
  


//+------------------------------------------------------------------+

string TypeMnem(int type) {
  switch (type) {
    case OP_BUY: return("buy");
    case OP_SELL: return("sell");
    case OP_BUYLIMIT: return("buy limit");
    case OP_SELLLIMIT: return("sell limit");
    case OP_BUYSTOP: return("buy stop");
    case OP_SELLSTOP: return("sell stop");
    default: return("???");
  }
}