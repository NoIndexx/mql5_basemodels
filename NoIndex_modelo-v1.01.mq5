//+------------------------------------------------------------------+
//|                                               NoIndex_modelo.mq5 |
//|                                                          NoIndex |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "NoIndex"
#property link      "https://www.mql5.com"
#property version   "1.01"


#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//                                                                   |
//                     Parâmetros de entrada                         |
//                                                                   |
//+------------------------------------------------------------------+


input string   titulo1="";     // parametros dos contratos
input double   contratos=0.0; // numero de contratos
input double   stoploss=0.0; // stoploss da operação
input double   takeprofit=0.0; // stopgain da operação

input string titulo2="";     // parametros do horário
input int hAbertura=9; // Hora de Abertura
input int mAbertura=15; // Minuto de Abertura
input int hFechamento=17; // Hora de Fechamento
input int mFechamento=45; // Minuto de Fechamento

input string titulo3="";     // parametros das medias
input int ma_fast_period=8;                              // período da média móvel rápida
input ENUM_MA_METHOD ma_fast_method=MODE_SMA;          // método da média móvel rápida
input int ma_med_period =20;                             // período da média móvel média
input ENUM_MA_METHOD ma_med_method=MODE_SMA;            // método da média móvel média
input int ma_slow_period =200;                           // período da média móvel lenta
input ENUM_MA_METHOD ma_slow_method =MODE_SMA;           // método da média móvel lenta


//+------------------------------------------------------------------+
//|                     VARIAVEIS GLOBAIS DE MONITORAMENTO           |
//+------------------------------------------------------------------+


int gl_Tick=0;                      // CONTAR O NUMERO DE NEGOCIOS
int gl_Order=0;                   // COMPRA OU VENDA NÃO FAZ NADA
string gl_Tendencia_MA="INDEF";  // Guarda o Status da posição das médias

//+------------------------------------------------------------------+
//|                     VARIAVEIS GLOBAIS DE GESTÃO DE CUSTODIA      |
//+------------------------------------------------------------------+


bool gl_OpenPosition=false;       // Tenho posição aberta (1)
long gl_PositionType= -1;         // Estou comprado ou estou vendido (2)
double gl_Contratos=0;            // Qual a posição de custodia no servidor (3)
bool gl_DobraMao=false;           // Indica virada de mão


//+------------------------------------------------------------------+
//|         VARIAVEIS GLOBAIS DE GESTÃO DE ELEMENTOS GRÁFICOS        |
//+------------------------------------------------------------------+

bool glInitHandle1=false;     // HANDLE MEDIA MÓVEL RÁPIDA INICIALIZAÇÃO
bool glInitHandle2=false;     // HANDLE MEDIA MÓVEL MEDIANA INICIALIZAÇÃO
bool glInitHandle3=false;     // HANDLE MEDIA MÓVEL LENTA INICIALIZAÇÃO

bool glInitChart1=false;      //  MEDIA MÓVEL RÁPIDA FOI COLOCADA NO GRÁFICO
bool glInitChart2=false;      //  MEDIA MÓVEL MEDIANA FOI COLOCADA NO GRÁFICO
bool glInitChart3=false;      //  MEDIA MÓVEL LENTA FOI COLOCADA NO GRÁFICO


//+------------------------------------------------------------------+
//|                     Handles                                      |
//+------------------------------------------------------------------+

int iMA_fast_handle=INVALID_HANDLE;
int iMA_med_handle=INVALID_HANDLE;
int iMA_slow_handle=INVALID_HANDLE;



//+------------------------------------------------------------------+
//|                     Buffers                                      |
//+------------------------------------------------------------------+

double iMA_fast_buffer[]; // iMA_fast_buffer[0] iMA_fast_buffer[1]
double iMA_med_buffer[];      //
double iMA_slow_buffer[];    //

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+

   ResetLastError();
   Comment("Robozinho bala");
   
//+------------------------------------------------------------------+
//|       VARIAVEIS GLOBAIS DE MONITORAMENTO - Cópia de segurança    |
//+------------------------------------------------------------------+


    gl_Tick=0;  // CONTAR O NUMERO DE NEGOCIOS
    gl_Order=0; // COMPRA OU VENDA NÃO FAZ NADA
    gl_Tendencia_MA="INDEF";  // Guarda o Status da posição das médias

//+------------------------------------------------------------------+
// VARIAVEIS GLOBAIS DE GESTÃO DE CUSTODIA - Cópia de segurança      |
//+------------------------------------------------------------------+


   gl_OpenPosition=false;       // Tenho posição aberta (1)
   gl_PositionType= -1;         // Estou comprado ou estou vendido (2)
   gl_Contratos=0;            // Qual a posição de custodia no servidor (3)
   gl_DobraMao=false;           // Indica virada de mão
   
//+--------------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS DE GESTÃO DE ELEMENTOS GRÁFICOS - Cópia de segurança   |
//+--------------------------------------------------------------------------+

   glInitHandle1=false;     // HANDLE MEDIA MÓVEL RÁPIDA INICIALIZAÇÃO
   glInitHandle2=false;     // HANDLE MEDIA MÓVEL MEDIANA INICIALIZAÇÃO
   glInitHandle3=false;     // HANDLE MEDIA MÓVEL LENTA INICIALIZAÇÃO

   glInitChart1=false;      //  MEDIA MÓVEL RÁPIDA FOI COLOCADA NO GRÁFICO
   glInitChart2=false;      //  MEDIA MÓVEL MEDIANA FOI COLOCADA NO GRÁFICO
   glInitChart3=false;      //  MEDIA MÓVEL LENTA FOI COLOCADA NO GRÁFICO   
   


//+------------------------------------------------------------------+
//| VALIDAÇÃO DO TIPO DE CONTA DO USUÁRIO                            |
//+------------------------------------------------------------------+

   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)!=0)
     {
      Print("Robô permitido apenas em conta DEMO");
      return(INIT_FAILED);
     }


//+------------------------------------------------------------------+
//| ANALISE DE VARIAVEIS DE CONTRATOS                               |
//+------------------------------------------------------------------+

   if(contratos<=0)
     {
      Print("▀ O número de contratos não pode ser zero ou menor que zero.");
      return (INIT_FAILED);
     }
   if(stoploss<=0)
     {
      Print("▀ O stoploss não pode ser zero ou menor que zero.");
      return (INIT_FAILED);
     }
   if(takeprofit<=0)
     {
      Print("▀ O takeprofit não pode ser zero ou menor que zero.");
      return (INIT_FAILED);
     }

//+------------------------------------------------------------------+
//| ANALISE DE VARIAAVEIS DE HORÁRIO                                 |
//+------------------------------------------------------------------+
   if(hAbertura<=0 || hAbertura>23)
     {
      Print("▀ O horário de abertura não pode ser menor que zero, e o máximo é de até 23 horas");
      return (INIT_FAILED);
     }
   if(mAbertura<0 || mAbertura>59)
     {
      Print("▀ O minuto de abertura não pode ser menor que zero e não maior que 59");
      return (INIT_FAILED);
     }
   if(hFechamento<0 || hFechamento>23)
     {
      Print("▀ O horário de fechamento não pode ser menor que zero, e o máximo é de até 23 horas");
      return (INIT_FAILED);
     }
   if(mFechamento<0 || mFechamento>59)
     {
      Print("▀ O minuto de fechamento não pode ser menor que zero e não maior que 59");
      return (INIT_FAILED);
     }
   if(hFechamento<hAbertura)
     {
      Print("▀ O horário de fechamento não pode ser menor que o horário de abertura");
      return (INIT_FAILED);
     }

//+------------------------------------------------------------------+
//| ANALISE DE VARIAVEIS DAS MEDIAS                                  |
//+------------------------------------------------------------------+
   if(ma_fast_period<=0)
     {
      Print("▀ O período da média rápida não pode ser menor ou igual a zero.");
      return (INIT_FAILED);
     }
   if(ma_med_period<=0)
     {
      Print("▀ O período da média mediana não pode ser menor ou igual a zero.");
      return (INIT_FAILED);
     }
   if(ma_slow_period<=0)
     {
      Print("▀ O período da média lenta não pode ser menor ou igual a zero.");
      return (INIT_FAILED);
     }
   if(ma_slow_period<ma_med_period)
     {
      Print("▀ O período da média lenta não pode ser menor que a média mediana");
      return (INIT_FAILED);
     }
   if(ma_slow_period<ma_fast_period)
     {
      Print("▀ O período da média lenta não pode ser menor que a média rápida");
      return (INIT_FAILED);
     }
   if(ma_med_period<ma_fast_period)
     {
      Print("▀ O período da média mediana não pode ser menor que a média rápida");
      return (INIT_FAILED);
     }



//+------------------------------------------------------------------+
//|                     Handles                                      |
//+------------------------------------------------------------------+

   iMA_fast_handle=iMA(_Symbol,_Period,ma_fast_period,0,ma_fast_method,PRICE_CLOSE);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(iMA_fast_handle==INVALID_HANDLE)
     {
      Print("▀Erro criação do iMA_fast_handle:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitHandle1=true;
     }

   iMA_med_handle=iMA(_Symbol,_Period,ma_med_period,0,ma_med_method,PRICE_CLOSE);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(iMA_med_handle==INVALID_HANDLE)
     {
      Print("▀Erro criação do iMA_med_handle:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitHandle2=true;
     }

   iMA_slow_handle=iMA(_Symbol,_Period,ma_slow_period,0,ma_slow_method,PRICE_CLOSE);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(iMA_slow_handle==INVALID_HANDLE)
     {
      Print("▀Erro criação do iMA_slow_handle:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitHandle3=true;
     }

//+------------------------------------------------------------------+
//|                     ARRAYSETASSERIES                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ArraySetAsSeries(iMA_fast_buffer,true))
     {
      Print("▀Erro na criação do ArraySetAsSeries para iMA_fast_buffer:",GetLastError());
      return(INIT_FAILED);
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ArraySetAsSeries(iMA_med_buffer,true))
     {
      Print("▀Erro na criação do ArraySetAsSeries para iMA_med_buffer:",GetLastError());
      return(INIT_FAILED);
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ArraySetAsSeries(iMA_slow_buffer,true))
     {
      Print("▀Erro na criação do ArraySetAsSeries para iMA_slow_buffer:",GetLastError());
      return(INIT_FAILED);
     }
//+------------------------------------------------------------------+
//| CHART INDICATOR ADD                                              |
//+------------------------------------------------------------------+
   if(!ChartIndicatorAdd(ChartID(),0,iMA_fast_handle))
     {
      Print("▀Erro na plotagem do indicador iMA_fast_handle no gráfico:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitChart1=true;
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ChartIndicatorAdd(ChartID(),0,iMA_med_handle))
     {
      Print("▀Erro na plotagem do indicador iMA_med_handle no gráfico:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitChart2=true;
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!ChartIndicatorAdd(ChartID(),0,iMA_slow_handle))
     {
      Print("▀Erro na plotagem do indicador iMA_slow_handle no gráfico:",GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      glInitChart3=true;
     }

//+------------------------------------------------------------------+
//| Inicialização realizada com sucesso                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   Print("Inicialização realizada com sucesso");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+
   ResetLastError();
   Comment("");

//+------------------------------------------------------------------+
//| INDICATOR RELEASE                                                |
//+------------------------------------------------------------------+

   if(glInitHandle1==true && !IndicatorRelease(iMA_fast_handle))
      Print("▀Erro no release do iMA_fast_handle:",GetLastError());

   if(glInitHandle1==true && !IndicatorRelease(iMA_med_handle))
      Print("▀Erro no release do iMA_med_handle:",GetLastError());

   if(glInitHandle1==true && !IndicatorRelease(iMA_slow_handle))
      Print("▀Erro no release do iMA_slow_handle:",GetLastError());

//+------------------------------------------------------------------+
//| ARRAYFREE                                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ArrayFree(iMA_fast_buffer);
   ArrayFree(iMA_med_buffer);
   ArrayFree(iMA_slow_buffer);

//+------------------------------------------------------------------+
//| DELETE CHART INDICATOR                                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   string iMA_fast_chart=ChartIndicatorName(0,0,0);
   if(glInitChart1 && !ChartIndicatorDelete(0,0,iMA_fast_chart))
      Print("▀Erro na remoção da iMA_fast_chart:",GetLastError());

   string iMA_med_chart=ChartIndicatorName(0,0,0);
   if(glInitChart1 && !ChartIndicatorDelete(0,0,iMA_med_chart))
      Print("▀Erro na remoção da iMA_fast_chart:",GetLastError());

   string iMA_slow_chart=ChartIndicatorName(0,0,0);
   if(glInitChart1 && !ChartIndicatorDelete(0,0,iMA_slow_chart))
      Print("▀Erro na remoção da iMA_fast_chart:",GetLastError());


//+------------------------------------------------------------------+
//| DEINICIALIZAÇÃO REALIZADA COM SUCESSO                            |
//+------------------------------------------------------------------+

   Print("Deinicialização executada");

  }



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
  ResetLastError();
  
  
//+------------------------------------------------------------------+
//| Inicializa Copybuffer                                            |
//+------------------------------------------------------------------+  
  
   if(CopyBuffer(iMA_fast_handle,0,0,3,iMA_fast_buffer)!=3) // iMA_fast_buffer[0] iMA_fast_buffer[1] iMA_fast_buffer[2]
      {
      Print("▀Erro ao atualizar os valores do indicador da média móvel rápida:", GetLastError());
      return;
      }
   if(CopyBuffer(iMA_med_handle,0,0,3,iMA_med_buffer)!=3) // iMA_med_buffer[0] iMA_med_buffer[1] iMA_med_buffer[2]
      {
      Print("▀Erro ao atualizar os valores do indicador da média móvel médiana:", GetLastError());
      return;
      }  
   if(CopyBuffer(iMA_slow_handle,0,0,3,iMA_slow_buffer)!=3) // iMA_slow_buffer[0] iMA_slow_buffer[1] iMA_slow_buffer[2]
      {
      Print("▀Erro ao atualizar os valores do indicador da média móvel lenta:", GetLastError());
      return;
      }  
  
//+------------------------------------------------------------------+
//| Sincroniza Horário Servidor                                      |
//+------------------------------------------------------------------+  
  
  
   MqlDateTime dt; // Cria estrutura
   TimeCurrent(dt); // Popula a estrutura
   
   
//+------------------------------------------------------------------+
//| Atualiza variaveis de horários                                   |
//+------------------------------------------------------------------+    
  
   int loc_horarioAtual=dt.hour*60+dt.min;                     // horário atual em minutos
   int loc_horarioAbertura=hAbertura*60+mAbertura;             // horário de abertura em minutos
   int loc_horarioFechamento=hFechamento*60+mFechamento;       // horário de fechamento em minutos
   
   if (loc_horarioAtual<loc_horarioAbertura)
      {
      Comment("[Mercado Fechado  - Abertura]",dt.hour,":",dt.min); 
      return;     
      }
      
   if (loc_horarioAtual>loc_horarioFechamento)
      {
      Comment("[Mercado Fechado  - Fechamento]",dt.hour,":",dt.min); 
      return;     
      }      
      

  
//+------------------------------------------------------------------+
//| Variáveis Globais de Monitoramento                               |
//+------------------------------------------------------------------+  
  
  
   gl_Tick++;           //Contar o número de negócios
   gl_Order=0;          //Compra ou venda ou não faz nada
  
//+------------------------------------------------------------------+
//| Variáveis Globais de Gestão de Custódia                          |
//+------------------------------------------------------------------+    
  
   gl_OpenPosition=false;    // Tenho posição aberta (1)
   gl_PositionType=-1;       // Estou comprado ou estou vendido (2)
   gl_Contratos=0;           // Qual a posição de custódia no servidor (3)
   gl_DobraMao=false;        // Indica Virada de mão
  
//+------------------------------------------------------------------+
//| Atualiza Posição                                                 |
//+------------------------------------------------------------------+  


   gl_OpenPosition=PositionSelect(_Symbol);
   
   if(gl_OpenPosition==true)
      {
      gl_PositionType=PositionGetInteger(POSITION_TYPE);        // Comprado ou Vendido
      gl_Contratos=PositionGetDouble(POSITION_VOLUME);          // Quantos Contratos Custodia
      Print("⬜ Robô posicionado:",gl_Contratos," na posição de ",gl_PositionType);
      }
   else // glOpenPosition==false
      {
      gl_PositionType=WRONG_VALUE; // (-1)
      Print("⬜ Robô não posicionado:",gl_Contratos," na posição de ",gl_PositionType);
      }

//+------------------------------------------------------------------+
//| Compra                                                           |
//+------------------------------------------------------------------+  

   if((iMA_fast_buffer[0]>iMA_slow_buffer[0]) &&
      (iMA_fast_buffer[1]<iMA_slow_buffer[1]))
      {
      gl_Order=1;                         // PODE COMPRAR
      gl_Tendencia_MA="ALTA";             // Guarda status da posição das médias
      Print("⬜ Médias Cruzadas. Acionando Compra.");
      }

//+------------------------------------------------------------------+
//| Hold Compra                                                      |
//+------------------------------------------------------------------+ 

   if(gl_OpenPosition==true  &&
      gl_PositionType==POSITION_TYPE_BUY &&
      gl_Order==1)
      {
         gl_Order=0;    // Restrição de compra caso já esteja comprado
         Print("⬜ Acionando compra com robô já comprado. Desconsiderando.");
      }


//+------------------------------------------------------------------+
//| Venda                                                            |
//+------------------------------------------------------------------+ 

   if((iMA_fast_buffer[0]<iMA_slow_buffer[0]) && 
      (iMA_fast_buffer[1]>iMA_slow_buffer[1]))
      {
      gl_Order=-1;                                          // Pode vender
      gl_Tendencia_MA="BAIXA";                              // Guarda Status da Posição das Médias
      Print("⬜ Médias Cruzadas. Acionando Venda.");         
      }


//+------------------------------------------------------------------+
//| Hold Venda                                                       |
//+------------------------------------------------------------------+ 

   
   if(gl_OpenPosition==true  &&
      gl_PositionType==POSITION_TYPE_SELL &&
      gl_Order==-1)
      {
         gl_Order=0;    // Restrição de venda caso já esteja vendido
         Print("⬜ Acionando venda com robô já vendido. Desconsiderando.");
      }

//+------------------------------------------------------------------+
//| VIRADA DE MÃO                                                    |
//+------------------------------------------------------------------+ 

   if(gl_OpenPosition)
      if((gl_PositionType==POSITION_TYPE_BUY && gl_Order==-1) ||
         (gl_PositionType==POSITION_TYPE_SELL && gl_Order==1))
         {
         
         gl_DobraMao=true;
         Print ("⬜ Acionado virada de mão");         
         }



//+------------------------------------------------------------------+
//| Comentário Gráfico                                               |
//+------------------------------------------------------------------+ 


   Comment ("[EM EXECUÇÃO] NEGOCIOS:", gl_Tick, " | Direção: ", gl_Tendencia_MA, " | CUSTODIA: ", gl_Contratos);




    Comment("[Mercado Aberto]",dt.hour,":",dt.min);
    
    
    
//+------------------------------------------------------------------+
//| Order Placement                                                  |
//+------------------------------------------------------------------+ 

   if(gl_Order!=0)
      {
      
         //+------------------------------------------------------------------+
         //| Atualiza Preço                                                   |
         //+------------------------------------------------------------------+ 
      
         MqlTick price_info;
         ZeroMemory(price_info);
         
         if (!SymbolInfoTick(_Symbol,price_info))
         {
         Print("▀Falha na atualização do Preço:", GetLastError());
         return;         
         }
      
         //+------------------------------------------------------------------+
         //| Prepara Envio da Ordem                                           |
         //+------------------------------------------------------------------+       
         
         double loc_NumeroContratos = contratos;
         
         if (gl_DobraMao==true)
         {
         loc_NumeroContratos=contratos*2;
         Print("⬜ Dobrando número de contratos para a operação.");
         }
         
         if(gl_Order==1)
         {
         Trade.Buy(loc_NumeroContratos,_Symbol,price_info.ask,(price_info.ask-stoploss), (price_info.ask+takeprofit), "[COMPRA]");
         Print("⬜ Executada ordem de compra");
         }
         
         if (gl_Order==-1)
         {
         Trade.Sell(loc_NumeroContratos,_Symbol,price_info.bid,(price_info.bid+stoploss), (price_info.ask-takeprofit), "[VENDA]");
         Print("⬜ Executada ordem de venda");
         }     
      }
}

  
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {

  }
//+------------------------------------------------------------------+
