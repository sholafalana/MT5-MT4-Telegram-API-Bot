//+------------------------------------------------------------------+
//|                                            TelegramAlert_MT4.mq4 |
//|                                        Copyright 2020, Assetbase |
//|                                         https://t.me/assetbaseTS |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Assetbase"
#property link      "https://t.me/assetbaseTS"
#property version   "3.00"
#property strict

#property strict
#include <Telegram.mqh>


//--- input parameters
input string InpChannelName="@myPublicGroupName";//Channel Name
input string InpToken="insert telegram bot API here";//Token
extern string mySigalname = "Enter my signal name";
input string _template = ""; //TemplateName e.g ADX

input bool AlertonTelegram = true;
input bool UseFormat_forCopier = false;
input bool SendScreenShot = false;
input ENUM_TIMEFRAMES ScreenShotTimeFrame = PERIOD_CURRENT;
input bool MobileNotification = false;
input bool EmailNotification = false;
uint   ServerDelayMilliseconds = 300;
string AllowSymbols            = "";              // Allow Trading Symbols (Ex: EURUSDq,EURUSDx,EURUSDa)

CCustomBot bot;
bool checked;
uint   pushdelay     = 0;
bool   telegram_runningstatus = false;

int    ordersize            = 0;
int    orderids[];
double orderopenprice[];
double orderlot[];
double ordersl[];
double ordertp[];
bool   orderchanged           = false;
bool   orderpartiallyclosed   = false;
int    orderpartiallyclosedid = -1;

int    prev_ordersize         = 0;

//--- Globales File
string local_symbolallow[];
int    symbolallow_size = 0;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init()
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_KEYDOWN &&
      lparam=='Q')
     {

      bot.SendMessage(InpChannelName,"ee\nAt:100\nDDDD");
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   StopTelegramServer();

  }
bool copmod = false;
//+------------------------------------------------------------------+
//| Expert program start function                                    |
//+------------------------------------------------------------------+
void start()
  {
   if(DetectEnvironment() == false)
     {
      Alert("Error: The property is fail, please check and try again.");
      return;
     }

   StartTelegramServer();

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DetectEnvironment()
  {


   

   pushdelay     = (ServerDelayMilliseconds > 0) ? ServerDelayMilliseconds : 10;
   telegram_runningstatus  = false;

// Load the Symbol allow map
   if(AllowSymbols != "")
     {
      string symboldata[];
      int    symbolsize = StringSplit(AllowSymbols, ',', symboldata);
      int    symbolindex = 0;

      ArrayResize(local_symbolallow, symbolsize);

      for(symbolindex=0; symbolindex<symbolsize; symbolindex++)
        {
         if(symboldata[symbolindex] == "")
            continue;

         local_symbolallow[symbolindex] = symboldata[symbolindex];
        }

      symbolallow_size = symbolsize;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Start the Telegram server                                        |
//+------------------------------------------------------------------+
int StartTelegramServer()
  {
   
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

   GetCurrentOrdersOnStart();

   int  changed     = 0;
   uint delay   =    pushdelay;
   uint ticketstart = 0;
   uint tickcount   = 0;

   telegram_runningstatus = true;

   while(!IsStopped())
     {
      ticketstart = GetTickCount();
      changed = GetCurrentOrdersOnTicket();

      if(changed > 0)
         UpdateCurrentOrdersOnTicket();

      tickcount = GetTickCount() - ticketstart;

      if(delay > tickcount)
         Sleep(delay-tickcount-2);
     }


  
   return(0);
  }

//+------------------------------------------------------------------+
//| Stop the Telegram server                                         |
//+------------------------------------------------------------------+
void StopTelegramServer()
  {


   ArrayFree(orderids);
   ArrayFree(orderopenprice);
   ArrayFree(orderlot);
   ArrayFree(ordersl);
   ArrayFree(ordertp);
   ArrayFree(local_symbolallow);



   telegram_runningstatus = false;
  }

//+------------------------------------------------------------------+
//| Get all of the orders                                            |
//+------------------------------------------------------------------+
void GetCurrentOrdersOnStart()
  {
   prev_ordersize = 0;
   ordersize      = OrdersTotal();

   if(ordersize == prev_ordersize)
      return;

   if(ordersize > 0)
     {
      ArrayResize(orderids, ordersize);
      ArrayResize(orderopenprice, ordersize);
      ArrayResize(orderlot, ordersize);
      ArrayResize(ordersl, ordersize);
      ArrayResize(ordertp, ordersize);
     }

   prev_ordersize = ordersize;

   int orderindex = 0;

// Save the orders to cache
   for(orderindex=0; orderindex<ordersize; orderindex++)
     {
      if(OrderSelect(orderindex, SELECT_BY_POS, MODE_TRADES) == false)
         continue;

      orderids[orderindex]       = OrderTicket();
      orderopenprice[orderindex] = OrderOpenPrice();
      orderlot[orderindex]       = OrderLots();
      ordersl[orderindex]        = OrderStopLoss();
      ordertp[orderindex]        = OrderTakeProfit();
     }
  }

//+------------------------------------------------------------------+
//| Get all of the orders                                            |
//+------------------------------------------------------------------+
int GetCurrentOrdersOnTicket()
  {
   ordersize = OrdersTotal();

   int changed = 0;

   if(ordersize > prev_ordersize)
     {
      // Trade has been added
      changed = PushOrderOpen();
     }
   else
      if(ordersize < prev_ordersize)
        {
         // Trade has been closed
         changed = PushOrderClosed();
        }
      else
         if(ordersize == prev_ordersize)
           {
            // Trade has been modify
            changed = PushOrderModify();
           }

   return changed;
  }

//+------------------------------------------------------------------+
//| Update all of the orders status                                  |
//+------------------------------------------------------------------+
void UpdateCurrentOrdersOnTicket()
  {
   if(ordersize > 0)
     {
      ArrayResize(orderids, ordersize);
      ArrayResize(orderopenprice, ordersize);
      ArrayResize(orderlot, ordersize);
      ArrayResize(ordersl, ordersize);
      ArrayResize(ordertp, ordersize);
     }

   int orderindex = 0;

// Save the orders to cache
   for(orderindex=0; orderindex<ordersize; orderindex++)
     {
      if(OrderSelect(orderindex, SELECT_BY_POS, MODE_TRADES) == false)
         continue;

      orderids[orderindex]       = OrderTicket();
      orderopenprice[orderindex] = OrderOpenPrice();
      orderlot[orderindex]       = OrderLots();
      ordersl[orderindex]        = OrderStopLoss();
      ordertp[orderindex]        = OrderTakeProfit();
     }

// Changed the old orders count as current orders count
   prev_ordersize = ordersize;
  }

//+------------------------------------------------------------------+
//| Push the open order to all of the subscriber                     |
//+------------------------------------------------------------------+
int PushOrderOpen()
  {
   int changed    = 0;
   int orderindex = 0;
   string message="";
   for(orderindex=0; orderindex<ordersize; orderindex++)
     {
      if(OrderSelect(orderindex, SELECT_BY_POS, MODE_TRADES) == false)
         continue;

      if(FindOrderInPrevPool(OrderTicket()) == false)
        {
         if(GetOrderSymbolAllowed(OrderSymbol()) == false)
            continue;

         Print("Order Added:", OrderSymbol(), ", Size:", ArraySize(orderids), ", OrderId:", OrderTicket());
         if(UseFormat_forCopier == false){
         message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                               OrderSymbol(),TypeMnem(OrderType()),"OPEN",
                               DoubleToString(OrderOpenPrice(),MarketInfo(OrderSymbol(),MODE_DIGITS)),
                               TimeToString(OrderOpenTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), MarketInfo(OrderSymbol(),MODE_DIGITS)),DoubleToString(OrderStopLoss(), MarketInfo(OrderSymbol(),MODE_DIGITS)));
                               }
                               
                                if(UseFormat_forCopier == true){
         message =StringFormat(" \nAssetname: %s\nType: %s\nStopLoss: %s\nTakeProfit: %s\nLots: %s\nComment: %s",
                                  OrderSymbol(),
                                  TypeMnem(OrderType()),
                                 DoubleToString(OrderStopLoss(), MarketInfo(OrderSymbol(),MODE_DIGITS)),
                                 DoubleToString(OrderTakeProfit(), MarketInfo(OrderSymbol(),MODE_DIGITS)),
                                  DoubleToString(OrderLots(), 2),
                                  mySigalname


                                 );
                                 
                                 }

         PushToSubscriber(OrderSymbol(),message);

         changed ++;
        }
     }

   return changed;
  }

//+------------------------------------------------------------------+
//| Push the close order to all of the subscriber                    |
//+------------------------------------------------------------------+
int PushOrderClosed()
  {
   int      changed    = 0;
   int      orderindex = 0;
   datetime ctm;
   string message;

   for(orderindex=0; orderindex<prev_ordersize; orderindex++)
     {
      if(OrderSelect(orderids[orderindex], SELECT_BY_TICKET, MODE_TRADES) == false)
         continue;

      ctm = OrderCloseTime();

      if(ctm > 0)
        {
         if(GetOrderSymbolAllowed(OrderSymbol()) == false)
            continue;

         Print("Order Closed:", OrderSymbol(), ", Size:", ArraySize(orderids), ", OrderId:", OrderTicket());
         message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                               OrderSymbol(),TypeMnem(OrderType()),"CLOSED",
                               DoubleToString(OrderClosePrice(),MarketInfo(OrderSymbol(),MODE_DIGITS)),
                               TimeToString(OrderCloseTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), MarketInfo(OrderSymbol(),MODE_DIGITS)),DoubleToString(OrderStopLoss(), MarketInfo(OrderSymbol(),MODE_DIGITS)));
         PushToSubscriber(OrderSymbol(),message);

         changed ++;
        }
     }

   return changed;
  }

//+------------------------------------------------------------------+
//| Push the modify order to all of the subscriber                   |
//+------------------------------------------------------------------+
int PushOrderModify()
  {
   int changed    = 0;
   int orderindex = 0;
   string message;
   for(orderindex=0; orderindex<ordersize; orderindex++)
     {
      orderchanged           = false;
      orderpartiallyclosed   = false;
      orderpartiallyclosedid = -1;

      if(OrderSelect(orderindex, SELECT_BY_POS, MODE_TRADES) == false)
         continue;

      if(GetOrderSymbolAllowed(OrderSymbol()) == false)
         continue;

      if(orderlot[orderindex] != OrderLots())
        {
         orderchanged = true;

         string ordercomment = OrderComment();
         int    orderid      = 0;

         // Partially closed a trade
         // Partially closed is a different lots from trade
         if(StringFind(ordercomment, "from #", 0) >= 0)
           {
            if(StringReplace(ordercomment, "from #", "") >= 0)
              {
               orderpartiallyclosed   = true;
               orderpartiallyclosedid = StringToInteger(ordercomment);
              }
           }
        }

      if(ordersl[orderindex] != OrderStopLoss())
         orderchanged = true;

      if(ordertp[orderindex] != OrderTakeProfit())
         orderchanged = true;

      // Temporarily method for recognize modify order or part-closed order
      // Part-close order will close order by a litte lots and re-generate an new order with new order id
      if(orderchanged == true)
        {
         if(orderpartiallyclosed == true)
           {
            Print("Partially Closed:", OrderSymbol(), ", Size:", ArraySize(orderids), ", OrderId:", OrderTicket(), ", Before OrderId: ", orderpartiallyclosedid);
            message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                                  OrderSymbol(),TypeMnem(OrderType()),"Partially Closed",
                                  DoubleToString(OrderOpenPrice(),MarketInfo(OrderSymbol(),MODE_DIGITS)),
                                  TimeToString(TimeCurrent()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), MarketInfo(OrderSymbol(),MODE_DIGITS)),DoubleToString(OrderStopLoss(), MarketInfo(OrderSymbol(),MODE_DIGITS)));
            PushToSubscriber(OrderSymbol(),message);
           }
         else
           {
            Print("Order Modify:", OrderSymbol(), ", Size:", ArraySize(orderids), ", OrderId:", OrderTicket());
            message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                                  OrderSymbol(),TypeMnem(OrderType()),"Order Modified",
                                  DoubleToString(OrderOpenPrice(),MarketInfo(OrderSymbol(),MODE_DIGITS)),
                                  TimeToString(TimeCurrent()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), MarketInfo(OrderSymbol(),MODE_DIGITS)),DoubleToString(OrderStopLoss(), MarketInfo(OrderSymbol(),MODE_DIGITS)));
            PushToSubscriber(OrderSymbol(),message);
           }

         changed ++;
        }
     }

   return changed;
  }

//+------------------------------------------------------------------+
//| Push the message                                                  |
//+------------------------------------------------------------------+
void PushToSubscriber(const string symbl,const string message)
  {
   if(message == "")
      return ;

   if(MobileNotification)
     {
      SendNotification(message);
     }
   if(EmailNotification)
     {
      SendMail("Order Notification",message);
     }
   if(AlertonTelegram)
     {
    //  bot.SendMessage(InpChannelName,message);
     }
     
      if(SendScreenShot)
     {
      if(StringFind(symbl,"null") != -1)
    return ;
      sendSnapShots(symbl,ScreenShotTimeFrame,message);
     }
     
      if(SendScreenShot == false)
     {
     bot.SendMessage(InpChannelName,message);
     }
     


  }

//+------------------------------------------------------------------+
//| Get the symbol allowd on trading                                 |
//+------------------------------------------------------------------+
bool GetOrderSymbolAllowed(const string symbol)
  {
   bool result = true;

   if(symbolallow_size == 0)
      return result;

// Change result as FALSE when allow list is not empty
   result = false;

   int symbolindex = 0;

   for(symbolindex=0; symbolindex<symbolallow_size; symbolindex++)
     {
      if(local_symbolallow[symbolindex] == "")
         continue;

      if(symbol == local_symbolallow[symbolindex])
        {
         result = true;

         break;
        }
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Find a order by ticket id                                        |
//+------------------------------------------------------------------+
bool FindOrderInPrevPool(const int order_ticketid)
  {
   int orderfound = 0;
   int orderindex = 0;

   if(prev_ordersize == 0)
      return false;

   for(orderindex=0; orderindex<prev_ordersize; orderindex++)
     {
      if(order_ticketid == orderids[orderindex])
         orderfound ++;
     }

   return (orderfound > 0) ? true : false;
  }
  
  int sendSnapShots(string thesymbol, ENUM_TIMEFRAMES _period, string message){
   
     int result=0;
           long chart_id=ChartOpen(thesymbol,_period);
     // if(chart_id==0)
     //    return(ERR_CHART_NOT_FOUND);

      ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);

      //--- updates chart
      int wait=60;
      while(--wait>0)
        {
         if(SeriesInfoInteger(thesymbol,_period,SERIES_SYNCHRONIZED))
            break;
         Sleep(500);
        }

      if(_template!= ""){
         ChartApplyTemplate(chart_id,_template);
        //    PrintError(_LastError,InpLanguage);
          //  ChartApplyTemplate(chart_id,_template);
         }
      ChartRedraw(chart_id);
      Sleep(500);

      ChartSetInteger(chart_id,CHART_SHOW_GRID,false);

      ChartSetInteger(chart_id,CHART_SHOW_PERIOD_SEP,false);

      string filename=StringFormat("%s%d.gif",thesymbol,_period);

      if(FileIsExist(filename))
         FileDelete(filename);
      ChartRedraw(chart_id);

      Sleep(100);

      if(ChartScreenShot(chart_id,filename,800,600,ALIGN_RIGHT))
        {
         Sleep(100);

         //--- waitng 30 sec for save screenshot 
         wait=30;
         while(!FileIsExist(filename) && --wait>0)
            Sleep(500);

         //---
         if(FileIsExist(filename))
           {
            string screen_id;
           
            result=bot.SendPhoto(screen_id,InpChannelName,filename,thesymbol + message);
            
       
           }
        

        } 

      ChartClose(chart_id);    
   
   
   
  return result; 
   }
  
  


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TypeMnem(int type)
  {
   switch(type)
     {
      case OP_BUY:
         return("buy");
      case OP_SELL:
         return("sell");
      case OP_BUYLIMIT:
         return("buy limit");
      case OP_SELLLIMIT:
         return("sell limit");
      case OP_BUYSTOP:
         return("buy stop");
      case OP_SELLSTOP:
         return("sell stop");
      default:
         return("???");
     }
  }
