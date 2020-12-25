//+------------------------------------------------------------------+
//|                                             TelegramAlertMT4.mq4 |
//|                                 Copyright 2020, SafeCarp Finance |
//|     https://www.upwork.com/o/profiles/users/~01f385ced64055abbc/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, SafeCarp Finance"
#property link      "https://www.upwork.com/o/profiles/users/~01f385ced64055abbc/"
#property version   "2.00"
#property strict
#include <Telegram.mqh>


//--- input parameters
input string InpChannelName="@mychannelname";//Channel Name
input string InpToken="insert telegram bot API here";//Token
extern string mySigalname = "Enter my signal name";

input bool AlertonTelegram = true;
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


   if(IsDllsAllowed() == false)
     {
      Print("DLL call is not allowed. ", "TelegramSignalAlert", " cannot run.");
      return false;
     }


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
         message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                               OrderSymbol(),TypeMnem(OrderType()),"OPEN",
                               DoubleToString(OrderOpenPrice(),Digits),
                               TimeToString(OrderOpenTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits));
         PushToSubscriber(message);

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
                               DoubleToString(OrderClosePrice(),Digits),
                               TimeToString(OrderCloseTime()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits));
         PushToSubscriber(message);

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
                                  DoubleToString(OrderOpenPrice(),Digits),
                                  TimeToString(TimeCurrent()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits));
            PushToSubscriber(message);
           }
         else
           {
            Print("Order Modify:", OrderSymbol(), ", Size:", ArraySize(orderids), ", OrderId:", OrderTicket());
            message =StringFormat("Name: %s\nSymbol: %s\nType: %s\nAction: %s\nPrice: %s\nTime: %s\nLots: %s\nTakeProfit: %s\nStopLoss: %s",mySigalname,
                                  OrderSymbol(),TypeMnem(OrderType()),"Order Modified",
                                  DoubleToString(OrderOpenPrice(),Digits),
                                  TimeToString(TimeCurrent()),DoubleToString(OrderLots(), 2),DoubleToString(OrderTakeProfit(), Digits),DoubleToString(OrderStopLoss(), Digits));
            PushToSubscriber(message);
           }

         changed ++;
        }
     }

   return changed;
  }

//+------------------------------------------------------------------+
//| Push the message                                                  |
//+------------------------------------------------------------------+
void PushToSubscriber(const string message)
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
