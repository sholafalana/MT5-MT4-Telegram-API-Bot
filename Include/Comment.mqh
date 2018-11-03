//+------------------------------------------------------------------+
//|                                                      Comment.mqh |
//|                                                        avoitenko |
//|                        https://login.mql5.com/en/users/avoitenko |
//+------------------------------------------------------------------+
#property copyright  "avoitenko"
#property link       "https://login.mql5.com/en/users/avoitenko"
#property version    "1.00"
#property strict

#include <Canvas/Canvas.mqh>
#include <Arrays/List.mqh>

//---
#define EVENT_NO_EVENTS 0
#define EVENT_MOVE      1
#define EVENT_CHANGE    2
//+------------------------------------------------------------------+
//|   TComment                                                       |
//+------------------------------------------------------------------+
class TComment : public CObject
  {
public:
   string            text;
   color             colour;
  };
//+------------------------------------------------------------------+
//|   CComment                                                       |
//+------------------------------------------------------------------+
class CComment
  {
private:
   CPoint            m_temp;
   CCanvas           m_comment;
   CPoint            m_pos;
   CList             m_list;
   CSize             m_size;
   //---   
   string            m_name;
   string            m_font_name;
   int               m_font_size;
   bool              m_font_bold;
   double            m_font_interval;
   color             m_border_color;
   color             m_back_color;
   uchar             m_back_alpha;
   bool              m_graph_mode;
   bool              m_auto_colors;
   color             m_auto_back_color;
   color             m_auto_text_color;
   color             m_auto_border_color;
   color             m_chart_back_color;
   //+------------------------------------------------------------------+
   color Color2Gray(const color value)
     {
      int gray=(int)round(0.3*GETRGBR(value)+0.59*GETRGBG(value)+0.11*GETRGBB(value));
      if(gray>255) gray=255;
      return((color)ARGB(0,gray,gray,gray));
     }
   //+------------------------------------------------------------------+
   uchar GrayChannel(const color value)
     {
      int gray=(int)round(0.3*GETRGBR(value)+0.59*GETRGBG(value)+0.11*GETRGBB(value));
      if(gray>255) gray=255;
      return((uchar)gray);
     }
   //+------------------------------------------------------------------+
   color Bright(const color value,const int percent)
     {
      int r,g,b;
      //---   
      r=GETRGBR(value);
      g=GETRGBG(value);
      b=GETRGBB(value);
      //---
      if(percent>=0)
        {
         r+=(255-r)*percent/100;
         if(r>255)r=255;

         g+=(255-g)*percent/100;
         if(g>255)g=255;

         b+=(255-b)*percent/100;
         if(b>255)b=255;
        }
      else
        {
         r+=r*percent/100;
         if(r<0)r=0;

         g+=g*percent/100;
         if(g<0)g=0;

         b+=b*percent/100;
         if(b<0)b=0;
        }
      //---
      return(ARGB(0,r,g,b));
     }
   //+------------------------------------------------------------------+
   void CalcColors()
     {
      m_auto_back_color=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
      color m_back_gray=Color2Gray(m_auto_back_color);
      uchar channel=GrayChannel(m_back_gray);
      //---
      if(channel>120)
        {
         if(m_back_color==clrNONE)
            m_auto_border_color=clrNONE;
         else
            m_auto_border_color=Bright(m_back_gray,-30);

         m_auto_text_color=Bright(m_back_gray,-80);
        }
      else
        {
         if(m_back_color==clrNONE)
            m_auto_border_color=clrNONE;
         else
            m_auto_border_color=Bright(m_back_gray,30);

         m_auto_text_color=Bright(m_back_gray,80);
        }
     }
public:
   //+------------------------------------------------------------------+
   void  CComment(void)
     {
      m_name=NULL;
      m_font_name="Lucida Console";
      m_font_size=14;
      m_font_bold=false;
      m_font_interval=1.7;
      m_border_color=clrNONE;
      m_back_color=clrBlack;
      m_back_alpha=255;
      m_graph_mode=true;
      m_auto_colors=false;
      m_chart_back_color=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
      m_auto_back_color=clrBlack;
      m_auto_border_color=clrNONE;
      //---
      ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
     };
   //+------------------------------------------------------------------+
   void  Create(const string name,const uint x,const uint y)
     {
      m_name=name;
      m_pos.x=(int)x;
      m_pos.y=(int)y;
     };
   //+------------------------------------------------------------------+
   int CoordY(){return(m_pos.y);}
   //+------------------------------------------------------------------+
   int CoordX(){return(m_pos.x);}
   //+------------------------------------------------------------------+
   void  Move(const uint x,const uint y)
     {
      m_pos.x=(int)x;
      m_pos.y=(int)y;

      if(ObjectGetInteger(0,m_name,OBJPROP_XDISTANCE)!=m_pos.x)
         ObjectSetInteger(0,m_name,OBJPROP_XDISTANCE,m_pos.x);

      if(ObjectGetInteger(0,m_name,OBJPROP_YDISTANCE)!=m_pos.y)
         ObjectSetInteger(0,m_name,OBJPROP_YDISTANCE,m_pos.y);
     };
   //+------------------------------------------------------------------+
   void SetAutoColors(const bool value)
     {
      m_auto_colors=value;
      if(value)
         CalcColors();
     }
   //+------------------------------------------------------------------+
   void  SetGraphMode(const bool value)
     {
      m_graph_mode=value;
     };
   //+------------------------------------------------------------------+
   void  SetText(const int row,const string text,const color colour)
     {
      if(row<0)
         return;

      //---
      int total=m_list.Total();

      if(row<total)
        {
         TComment *item=m_list.GetNodeAtIndex(row);
         item.text=text;
         item.colour=colour;
        }
      else
        {
         //--- create new one string
         for(int i=total; i<=row; i++)
           {
            m_list.Add(new TComment);
            TComment *item=m_list.GetLastNode();
            if(row==i)
              {
               item.text=text;
               item.colour=colour;
              }
            else
              {
               item.text="";
               item.colour=clrNONE;
              }
           }
        }
     }
   //+------------------------------------------------------------------+
   void  SetFont(const string font_name,const int font_size,const bool bold,const double font_interval)
     {
      m_font_name=font_name;
      m_font_size=font_size;
      m_font_bold=bold;
      m_font_interval=font_interval;
     }
   //+------------------------------------------------------------------+
   void SetTransparency(const uchar alpha)
     {
      m_back_alpha=alpha;
     }

   //+------------------------------------------------------------------+
   void  SetColor(const color border,const color back,const uchar alpha)
     {
      m_border_color=border;
      m_back_color=back;
      m_back_alpha=alpha;
     }
   //+------------------------------------------------------------------+
   void  Destroy()
     {
      if(!m_graph_mode)
         Comment("");
      m_comment.Destroy();
      m_name=NULL;
     };
   //+------------------------------------------------------------------+
   void  Clear()
     {
      m_list.Clear();
     };
   //+------------------------------------------------------------------+
   int   OnChartEvent(const int id,const long lparam,const double dparam,const string sparam)
     {
      //--- mouse position
      CPoint p;
      p.x = (int)lparam;
      p.y = (int)dparam;

      //---
      if(id==CHARTEVENT_MOUSE_MOVE)
        {
         //--- panel size
         CSize psize;
         psize.cx=(int)ObjectGetInteger(0,m_name,OBJPROP_XSIZE);
         psize.cy=(int)ObjectGetInteger(0,m_name,OBJPROP_YSIZE);

         //--- panel position
         CPoint pan;
         pan.x=(int)ObjectGetInteger(0,m_name,OBJPROP_XDISTANCE);
         pan.y=(int)ObjectGetInteger(0,m_name,OBJPROP_YDISTANCE);

         //--- chart size
         CSize screen;
         screen.cx=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
         screen.cy=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);

         if(sparam=="1")
           {
            //---
            if(m_temp.x==-1 && 
               p.x>=pan.x && p.x<pan.x+psize.cx &&
               p.y>=pan.y && p.y<pan.y+psize.cy)
              {
               m_temp.x=p.x-pan.x;
              }
            //---
            if(m_temp.y==-1 && 
               p.x>=pan.x && p.x<pan.x+psize.cx &&
               p.y>=pan.y && p.y<pan.y+psize.cy)
              {
               m_temp.y=p.y-pan.y;
              }
            //---
            if(m_temp.x>=0 && m_temp.y>=0)
              {
               int new_x=p.x-m_temp.x;
               if(new_x>screen.cx-psize.cx)new_x=screen.cx-psize.cx;
               if(new_x<0)new_x=0;

               int new_y=p.y-m_temp.y;
               if(new_y>screen.cy-psize.cy)new_y=screen.cy-psize.cy;
               if(new_y<0)new_y=0;
               //---
               ObjectSetInteger(0,m_name,OBJPROP_XDISTANCE,new_x);
               m_pos.x=new_x;
               ObjectSetInteger(0,m_name,OBJPROP_YDISTANCE,new_y);
               m_pos.y=new_y;
               ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
#ifdef __MQL5__
               ChartRedraw();
#endif
               return(EVENT_MOVE);
              }
           }
         else
           {
            m_temp.x=-1;
            m_temp.y=-1;
            ChartSetInteger(0,CHART_MOUSE_SCROLL,true);
           }
        }
      //---  
      if(m_auto_colors && id==CHARTEVENT_CHART_CHANGE)
        {
         //--- changing background color event
         if(m_chart_back_color!=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND))
           {
            CalcColors();
            m_chart_back_color=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
            Show();
            return(EVENT_CHANGE);
           }
        }
      //---
      return(EVENT_NO_EVENTS);
     }
   //+------------------------------------------------------------------+
   void  Show()
     {
      int rows=m_list.Total();

      //--- text mode
      if(!m_graph_mode)
        {
         string text;
         for(int i=0; i<rows; i++)
           {
            TComment *item=m_list.GetNodeAtIndex(i);
            text+="\n"+item.text;
           }
         Comment(text);
         return;
        }

      m_comment.FontSet(m_font_name,m_font_size,m_font_bold?FW_BOLD:0);
      int text_height=m_comment.TextHeight(" ");
      int max_height=(rows)*(int)round(text_height*m_font_interval)+text_height;

      //--- calc max width
      int max_width=0;
      for(int i=0; i<rows; i++)
        {
         TComment *item=m_list.GetNodeAtIndex(i);
         int width=m_comment.TextWidth(item.text);
         if(width>max_width) max_width=width;
        }
      max_width+=text_height*2;

      //--- create panel
      if(ObjectFind(0,m_name)==-1)
        {
         m_comment.CreateBitmapLabel(0,0,m_name,m_pos.x,m_pos.y,max_width,max_height,COLOR_FORMAT_ARGB_NORMALIZE);
         ObjectSetString(0,m_name,OBJPROP_TOOLTIP,"\n");
        }
      else
        {
         //--- resize panel
         if(m_comment.Height()!=max_height || 
            m_comment.Width()!=max_width)
           {
            if(!m_comment.Resize(max_width,max_height))
              {
               ObjectDelete(0,m_name);
               ChartRedraw();
              }
           }

        }
      //--- 
      m_comment.Erase(ColorToARGB(m_auto_colors?m_auto_back_color:m_back_color,m_back_alpha));
      m_comment.Rectangle(0,0,max_width-1,max_height-1,ColorToARGB(m_auto_colors?m_auto_border_color:m_border_color));
      //---
      int h=text_height;
      for(int i=0; i<rows; i++)
        {
         TComment *item=m_list.GetNodeAtIndex(i);
         m_comment.TextOut(text_height,h,item.text,ColorToARGB(m_auto_colors?m_auto_text_color:item.colour));
         h+=(int)round(text_height*m_font_interval);
        }
      //---
      m_comment.Update();
     }
  };
//+------------------------------------------------------------------+
