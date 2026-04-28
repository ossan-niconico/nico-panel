//+------------------------------------------------------------------+
//|                                                    nico-panel.mq4|
//+------------------------------------------------------------------+
#property copyright "ossan_niconico"
#property link      ""
#property version   "8.01"
#property strict

//=== パネル設定 ====================================================
input string __1__             = "=== パネル設定 ===";
input int    PanelCorner       = 0;            // 初期位置 0=左上 1=右上 2=左下 3=右下
input int    PanelX            = 10;           // 初期X位置（px）
input int    PanelY            = 20;           // 初期Y位置（px）
input int    PanelWidth        = 300;          // パネル幅（px）
input color  PanelBgColor      = C'20,20,40';  // 背景色
input color  PanelBorderColor  = C'80,80,120'; // 枠線色
input int    FontSize          = 10;           // 文字サイズ（基準）
input int    RowPadding        = 10;           // 各行の余白

//=== ボタン色 ======================================================
input string __2__             = "=== ボタン色 ===";
input color  BuyColor          = C'30,100,200';
input color  SellColor         = clrCrimson;
input color  CloseAllColor     = C'220,220,220';
input color  CloseAllTxtColor  = C'20,20,20';

//=== スプレッド・タイマー ==========================================
input string __3__             = "=== スプレッド・タイマー ===";
input color  ClockColor        = clrWhite;     // 現在時刻の文字色
input color  SpreadColor       = clrYellow;    // スプレッドの文字色
input color  TimerColor        = clrAqua;      // Next barの文字色

//=== Total Pips 色設定 ============================================
input string __4__             = "=== Total Pips 色設定 ===";
input color  PipsPlusTxtColor  = clrRoyalBlue; // 文字色（プラス時）
input color  PipsMinusTxtColor = clrCrimson;   // 文字色（マイナス時）
input color  PipsBgColor       = clrWhite;     // 背景色（固定）

//=== 時間表示設定 ==================================================
input string __5__             = "=== 時間表示設定 ===";
input bool   ShowTimeInfo      = true;          // ポジション時間表示
input int    TimeOffsetHours   = 6;             // サーバー時間との差（日本: 夏=6 / 冬=7）
input color  OpenTimeColor     = C'120,220,120';
input color  CloseTimeColor    = C'220,160,160';

//=== 注文設定 ======================================================
input string __6__             = "=== 注文設定 ===";
input double DefaultLot        = 0.01;
input int    Slippage          = 3;
input int    MagicNumber       = 20240101;
input bool   UseAutoTPSL       = true;   // 自動TP/SLを有効にする
input int    TakeProfitPips    = 15;     // 利確（pips）
input int    StopLossPips      = 10;     // 損切（pips）

//=== TP/SL ライン設定 =============================================
input string __8__             = "=== TP/SL ライン設定 ===";
input bool   AutoShowLines     = true;          // ポジション保有時に自動表示
input color  LineTPColor       = C'60,140,255'; // TP線の色
input color  LineSLColor       = C'220,60,60';  // SL線の色
input int    LineWidth         = 2;             // 線の太さ

//------------------------------------------------------------------
#define PRE          "NP_"
#define MAX_POS      6
#define MAX_HIST     20

#define BG_PANEL     PRE"BgPanel"
#define BG_CLOCK     PRE"BgClock"
#define LBL_CLOCK    PRE"LblClock"
#define BG_SPREAD    PRE"BgSpread"
#define LBL_SPREAD   PRE"LblSpread"
#define BG_TIMER     PRE"BgTimer"
#define LBL_TIMER    PRE"LblTimer"
#define BTN_BUY      PRE"BtnBuy"
#define BTN_SELL     PRE"BtnSell"
#define EDT_LOT      PRE"EdtLot"
#define BG_OPEN_T    PRE"BgOpenT"
#define LBL_OPEN_T   PRE"LblOpenT"
#define BG_CLOSE_T   PRE"BgCloseT"
#define LBL_CLOSE_T  PRE"LblCloseT"
#define LBL_PIPS_BG  PRE"LblPipsBg"
#define LBL_PIPS     PRE"LblPips"
#define BTN_CLOSEALL PRE"BtnCloseAll"
#define BTN_RESET    PRE"BtnReset"
#define BTN_CLOSE    PRE"BtnClose"
#define BTN_OPEN     PRE"BtnOpen"
#define LBL_MINI_TXT PRE"LblMiniTxt"
#define BG_DRAG      PRE"BgDrag"
#define LBL_DRAG     PRE"LblDrag"
#define BTN_LINES    PRE"BtnLines"
#define LINE_TP      "NicoLineTP"
#define LINE_SL      "NicoLineSL"

string g_slotBg [MAX_POS];
string g_slotLbl[MAX_POS];
string g_slotBtn[MAX_POS];

double   g_lot           = 0.01;
bool     g_open          = true;
int      g_lastCount     = -1;
int      g_px            = 0;
int      g_py            = 0;
bool     g_dragging      = false;
int      g_dragOfsX      = 0;
int      g_dragOfsY      = 0;
double   g_closedPips    = 0.0;
datetime g_firstOpenTime = 0;
datetime g_allCloseTime  = 0;
bool     g_hadPosition   = false;
int      g_prevTickets[MAX_HIST];
int      g_prevCount     = 0;
bool     g_linesShown    = false;  // TP/SLライン表示状態
double   g_lastLineTP    = 0;      // 最後に設定したTPライン価格
double   g_lastLineSL    = 0;      // 最後に設定したSLライン価格

//+------------------------------------------------------------------+
int OnInit()
{
   g_lot          = DefaultLot;
   g_open         = false;  // 起動時は閉じた状態
   g_closedPips   = 0.0;
   g_firstOpenTime= 0;
   g_allCloseTime = 0;
   g_hadPosition  = false;
   g_prevCount    = 0;
   ArrayInitialize(g_prevTickets, -1);

   for(int i=0;i<MAX_POS;i++)
   {
      g_slotBg [i] = StringFormat(PRE"SlotBg%d",  i);
      g_slotLbl[i] = StringFormat(PRE"SlotLbl%d", i);
      g_slotBtn[i] = StringFormat(PRE"SlotBtn%d", i);
   }

   // マウス移動イベントを有効化（ドラッグ必須）
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   // 保存済み位置・開閉状態を復元（時間足切替後も維持）
   string gvX    = Symbol() + "_NP_PX";
   string gvY    = Symbol() + "_NP_PY";
   string gvOpen = Symbol() + "_NP_OPEN";
   if(GlobalVariableCheck(gvX) && GlobalVariableCheck(gvY))
   {
      g_px   = (int)GlobalVariableGet(gvX);
      g_py   = (int)GlobalVariableGet(gvY);
      g_open = GlobalVariableCheck(gvOpen) ? (GlobalVariableGet(gvOpen) > 0) : false;
   }
   else
   {
      CalcInitialBase();
      // g_open は初回起動時のみ false（閉じた状態）
   }

   BuildAll();
   EventSetTimer(1);   // 1秒タイマー：時刻更新 & ラインチェック用
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
   ObjectsDeleteAll(0, PRE);
   RemoveTPSLLines();
   ChartRedraw();
}

void OnTick()
{
   DetectClosedPositions();
   int cnt = CountPositions();
   if(cnt != g_lastCount) { g_lastCount=cnt; if(g_open) BuildAll(); }
   CheckPanelButtons();   // ボタン状態をポーリング（イベント補完）
   CheckAndApplyLines();  // ラインの変化を検知してOrderModify
   UpdateAll();
}

//---- 1秒タイマー：時刻更新 & ボタン・ライン補完チェック
void OnTimer()
{
   UpdateClock();
   CheckPanelButtons();
   CheckAndApplyLines();
   ChartRedraw();
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //---- マウス移動 → ドラッグ処理
   //  OBJ_BUTTONはマウスをキャプチャするためMOUSE_MOVEが届かない。
   //  そのためハンドルはOBJ_RECTANGLE_LABEL+OBJ_LABELにして、
   //  マウス座標がハンドル領域内か判定する方式を使う。
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mx  = (int)lparam;
      int my  = (int)dparam;
      bool lb = ((int)StringToInteger(sparam) & 1) != 0;

      if(lb)
      {
         int dragH = FontSize + 10;
         // ドラッグハンドル領域（パネル上部）の内側にいるかチェック
         bool overHandle = (mx >= g_px && mx <= g_px + PanelWidth + 10 &&
                            my >= g_py && my <= g_py + dragH + 9);

         if(!g_dragging && overHandle)
         {
            // ドラッグ開始：チャートスクロールを無効化
            g_dragging = true;
            g_dragOfsX = mx - g_px;
            g_dragOfsY = my - g_py;
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         }

         if(g_dragging)
         {
            int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            g_px = MathMax(0, MathMin(cw - PanelWidth - 10, mx - g_dragOfsX));
            g_py = MathMax(0, MathMin(ch - 60,              my - g_dragOfsY));
            // 位置を保存（時間足切替後も維持）
            GlobalVariableSet(Symbol() + "_NP_PX",   g_px);
            GlobalVariableSet(Symbol() + "_NP_PY",   g_py);
            GlobalVariableSet(Symbol() + "_NP_OPEN", g_open ? 1 : 0);
            BuildAll();
            UpdateAll();
         }
      }
      else
      {
         if(g_dragging)
            ChartSetInteger(0, CHART_MOUSE_SCROLL, true); // スクロール復元
         g_dragging = false;
      }
   }

   //---- オブジェクトクリック
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == BTN_BUY)      { ReadLot(); PlaceOrder(OP_BUY);  ResetBtn(BTN_BUY); }
      if(sparam == BTN_SELL)     { ReadLot(); PlaceOrder(OP_SELL); ResetBtn(BTN_SELL); }
      if(sparam == BTN_CLOSEALL) { CloseAll();                     ResetBtn(BTN_CLOSEALL); }
      if(sparam == BTN_CLOSE)    { Minimize(); }
      if(sparam == BTN_OPEN)     { Restore(); }
      if(sparam == BTN_LINES)    { ToggleLines();                  ResetBtn(BTN_LINES); }
      if(sparam == BTN_RESET)
      {
         g_closedPips=0.0; g_firstOpenTime=0; g_allCloseTime=0; g_hadPosition=false;
         UpdateAll(); ResetBtn(BTN_RESET);
      }
      for(int i=0;i<MAX_POS;i++)
         if(sparam==g_slotBtn[i]) { CloseSlot(i); ResetBtn(g_slotBtn[i]); }
      ChartRedraw();
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == EDT_LOT) ReadLot();

   //---- TP/SLライン ドラッグ完了 → 全ポジションに反映
   if(id == CHARTEVENT_OBJECT_DRAG)
   {
      if(sparam == LINE_TP)
      {
         double tp = NormalizeDouble(GetLinePrice(LINE_TP), _Digits);
         if(tp != 0) { g_lastLineTP = tp; ApplyTPLine(tp); }
      }
      if(sparam == LINE_SL)
      {
         double sl = NormalizeDouble(GetLinePrice(LINE_SL), _Digits);
         if(sl != 0) { g_lastLineSL = sl; ApplySLLine(sl); }
      }
      UpdateAll();
   }
}

//+------------------------------------------------------------------+
void CalcInitialBase()
{
   int pw = PanelWidth + 10;
   int ph = CalcTotalH();
   int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   g_px = (PanelCorner==1||PanelCorner==3) ? cw - PanelX - pw : PanelX;
   g_py = (PanelCorner==2||PanelCorner==3) ? ch - PanelY - ph : PanelY;
}

// パネルの総高さを計算（open/mini共通幅を保証）
int CalcTotalH()
{
   int fs   = FontSize;
   int bh   = fs + 24 + RowPadding;
   int rowH = fs + 20 + RowPadding;
   int timeH= ShowTimeInfo ? (rowH+4 + rowH+8) : 0;
   int nSlots = MathMin(CountPositions(), MAX_POS);
   return (fs+10)+4       // ドラッグ
        + rowH+4           // 時刻
        + rowH+4           // Spread
        + rowH+6           // Next bar
        + bh+8             // SELL/LOT/BUY
        + timeH            // Open/Close時間
        + rowH+8           // Total Pips
        + rowH+8           // Close All
        + rowH+8           // TP/SL Line
        + (nSlots>0 ? nSlots*(rowH+2)+6 : 0)
        + rowH+8           // Reset
        + rowH+10;         // 閉じる
}

//+------------------------------------------------------------------+
void BuildAll()
{
   ObjectsDeleteAll(0, PRE);   // NP_ プレフィックスのパネルオブジェクトのみ削除
   if(g_open) BuildMain();
   else        BuildMini();
   // ラインは別プレフィックス（NicoLine*）なので削除されない。
   // ただし g_linesShown=true なのにオブジェクトが無い場合は再生成する。
   if(g_linesShown)
   {
      if(ObjectFind(0, LINE_TP) < 0 && g_lastLineTP != 0)
         MkHLine(LINE_TP, g_lastLineTP, LineTPColor,
                 StringFormat("TP  %.5f  (drag to move all)", g_lastLineTP));
      if(ObjectFind(0, LINE_SL) < 0 && g_lastLineSL != 0)
         MkHLine(LINE_SL, g_lastLineSL, LineSLColor,
                 StringFormat("SL  %.5f  (drag to move all)", g_lastLineSL));
   }
   UpdateAll();
}

//+------------------------------------------------------------------+
void BuildMain()
{
   int pw   = PanelWidth;
   int fs   = FontSize;
   int bh   = fs + 24 + RowPadding;
   int rowH = fs + 20 + RowPadding;
   int bw   = pw/3 - 4;
   int ew   = pw - bw*2 - 8;
   int cnt  = CountPositions();
   int nSlots = MathMin(cnt, MAX_POS);
   int timeH  = ShowTimeInfo ? (rowH+4 + rowH+8) : 0;

   int totalH = (fs+10)+4
              + rowH+4
              + rowH+4
              + rowH+6
              + bh+8
              + timeH
              + rowH+8
              + rowH+8
              + rowH+8
              + (nSlots>0 ? nSlots*(rowH+2)+6 : 0)
              + rowH+8
              + rowH+10;

   int bx=g_px, by=g_py, x=bx+5, y=by+5;

   MkBg(BG_PANEL, bx, by, pw+10, totalH, PanelBgColor, PanelBorderColor);

   // ── ドラッグハンドル ─────────────────────────────────
   int dragH = fs + 10;
   MkBg(BG_DRAG, x, y, pw, dragH, C'40,40,65', C'60,60,100');
   MkCenterLabel(LBL_DRAG, "nico-panel", x, y, pw, dragH, C'160,160,200', C'40,40,65', fs-1);
   y += dragH + 4;

   // ── 現在時刻 ────────────────────────────────────────
   MkBg(BG_CLOCK, x, y, pw, rowH, C'10,10,28', C'60,60,100');
   MkCenterLabel(LBL_CLOCK, "00:00:00", x, y, pw, rowH, ClockColor, C'10,10,28', fs);
   y += rowH + 4;

   // ── Spread ──────────────────────────────────────────
   MkBg(BG_SPREAD, x, y, pw, rowH, C'10,10,28', C'60,60,100');
   MkCenterLabel(LBL_SPREAD, "Spread: --", x, y, pw, rowH, SpreadColor, C'10,10,28', fs);
   y += rowH + 4;

   // ── Next bar ────────────────────────────────────────
   MkBg(BG_TIMER, x, y, pw, rowH, C'10,10,28', C'60,60,100');
   MkCenterLabel(LBL_TIMER, "Next bar: --:--", x, y, pw, rowH, TimerColor, C'10,10,28', fs);
   y += rowH + 6;

   // ── SELL | ロット | BUY ──────────────────────────────
   MkBtn(BTN_SELL, "SELL", x, y, bw, bh, SellColor, clrWhite, fs+2, "Arial Bold");
   MkEdit(EDT_LOT, DoubleToStr(g_lot,2), x+bw+4, y, ew, bh, C'30,30,30', clrWhite, clrGold, fs);
   MkBtn(BTN_BUY,  "BUY",  x+bw+ew+8, y, bw, bh, BuyColor,  clrWhite, fs+2, "Arial Bold");
   y += bh + 8;

   // ── ポジション時間（オプション）─────────────────────
   if(ShowTimeInfo)
   {
      MkBg(BG_OPEN_T, x, y, pw, rowH, C'12,25,12', C'40,70,40');
      MkCenterLabel(LBL_OPEN_T, "Open:  --", x, y, pw, rowH, OpenTimeColor, C'12,25,12', fs-1);
      y += rowH + 4;
      MkBg(BG_CLOSE_T, x, y, pw, rowH, C'25,12,12', C'70,40,40');
      MkCenterLabel(LBL_CLOSE_T, "Close: --", x, y, pw, rowH, CloseTimeColor, C'25,12,12', fs-1);
      y += rowH + 8;
   }

   // ── Total Pips ──────────────────────────────────────
   MkBg(LBL_PIPS_BG, x, y, pw, rowH, PipsBgColor, C'180,180,180');
   MkCenterLabel(LBL_PIPS, "Total  0.0 Pips", x, y, pw, rowH, PipsPlusTxtColor, PipsBgColor, fs);
   y += rowH + 8;

   // ── Close All ───────────────────────────────────────
   MkBtn(BTN_CLOSEALL, "Close All", x, y, pw, rowH, CloseAllColor, CloseAllTxtColor, fs, "Arial Bold");
   y += rowH + 8;

   // ── TP/SL ライントグル ───────────────────────────────
   {
      color lbg = g_linesShown ? C'20,70,20' : C'50,50,70';
      color lfg = g_linesShown ? C'100,255,100' : C'150,150,180';
      string ltxt = g_linesShown ? "TP/SL Line: ON " : "TP/SL Line: OFF";
      MkBtn(BTN_LINES, ltxt, x, y, pw, rowH, lbg, lfg, fs-1, "Arial Bold");
   }
   y += rowH + 8;

   // ── 個別スロット ─────────────────────────────────────
   if(nSlots > 0)
   {
      int clW = 36;
      for(int i=0; i<nSlots; i++)
      {
         MkBg(g_slotBg[i], x, y, pw, rowH, C'35,35,55', C'60,60,90');
         MkLabel(g_slotLbl[i], "---", x+4, y+(rowH-fs)/2, clrWhite, fs-1, "Arial");
         MkBtn(g_slotBtn[i], "x", x+pw-clW, y, clW, rowH, C'160,40,40', clrWhite, fs, "Arial Bold");
         y += rowH + 2;
      }
      y += 4;
   }

   // ── Reset Pips ──────────────────────────────────────
   MkBtn(BTN_RESET, "Reset Pips", x, y, pw, rowH, C'60,60,80', C'180,180,180', fs-1, "Arial");
   y += rowH + 8;

   // ── 閉じる ──────────────────────────────────────────
   MkBtn(BTN_CLOSE, "閉じる", x, y, pw, rowH, C'80,80,80', clrWhite, fs-1, "Meiryo");
}

//+------------------------------------------------------------------+
//| ミニパネル：開いた時と同じ幅 pw+10 を使う                        |
//+------------------------------------------------------------------+
void BuildMini()
{
   int pw   = PanelWidth;
   int fs   = FontSize;
   int rowH = fs + 20 + RowPadding;
   int mw   = pw + 10;            // メインパネルと同じ幅
   int mh   = rowH * 2 + 14;     // 2行分

   int bx=g_px, by=g_py, x=bx+5, y=by+5;

   MkBg(BG_PANEL, bx, by, mw, mh, PanelBgColor, PanelBorderColor);

   // 1行目: nico-panel テキスト
   MkCenterLabel(LBL_MINI_TXT, "nico-panel", x, y, pw, rowH, clrWhite, PanelBgColor, fs);
   y += rowH + 4;

   // 2行目: Open ボタン
   MkBtn(BTN_OPEN, "Open", x, y, pw, rowH, C'60,130,60', clrWhite, fs, "Arial Bold");
}

//+------------------------------------------------------------------+
void Minimize()
{
   g_open = false;
   GlobalVariableSet(Symbol() + "_NP_OPEN", 0);
   // 位置の GlobalVariable を削除して初期位置にリセット
   GlobalVariableDel(Symbol() + "_NP_PX");
   GlobalVariableDel(Symbol() + "_NP_PY");
   CalcInitialBase();
   BuildAll();
}
void Restore()
{
   g_open = true;
   GlobalVariableSet(Symbol() + "_NP_OPEN", 1);
   GlobalVariableSet(Symbol() + "_NP_PX",   g_px);
   GlobalVariableSet(Symbol() + "_NP_PY",   g_py);
   BuildAll();
}

//+------------------------------------------------------------------+
//| 現在時刻ラベルだけ更新                                           |
//+------------------------------------------------------------------+
void UpdateClock()
{
   if(!g_open) return;
   datetime now = TimeCurrent() + TimeOffsetHours * 3600;
   ObjectSetString(0, LBL_CLOCK, OBJPROP_TEXT,
                   TimeToStr(now, TIME_DATE|TIME_SECONDS));
}

//+------------------------------------------------------------------+
void UpdateAll()
{
   // 時刻
   UpdateClock();

   // Spread
   int sp = (int)MarketInfo(Symbol(), MODE_SPREAD);
   double spPips = (_Digits==3||_Digits==5) ? sp/10.0 : (double)sp;
   SetTxt(LBL_SPREAD, "Spread: "+DoubleToStr(spPips,1)+" pips");

   // Next bar
   int rem = (int)(Time[0]+PeriodSeconds()-TimeCurrent());
   if(rem<0) rem=0;
   SetTxt(LBL_TIMER, StringFormat("Next bar: %02d:%02d", rem/60, rem%60));

   if(!g_open) { ChartRedraw(); return; }

   // Total Pips（背景固定・文字色だけ変える）
   double totalPips = CalcLivePips() + g_closedPips;
   SetTxt(LBL_PIPS, StringFormat("Total  %.1f Pips", totalPips));
   color pipsTxt = (totalPips >= 0) ? PipsPlusTxtColor : PipsMinusTxtColor;
   ObjectSetInteger(0, LBL_PIPS, OBJPROP_COLOR,  pipsTxt);
   ObjectSetInteger(0, LBL_PIPS, OBJPROP_BGCOLOR, PipsBgColor);

   // ポジション時間
   if(ShowTimeInfo)
   {
      int ofs = TimeOffsetHours * 3600;
      SetTxt(LBL_OPEN_T,  g_firstOpenTime>0
             ? "Open:  "+TimeToStr(g_firstOpenTime+ofs, TIME_DATE|TIME_MINUTES)
             : "Open:  --");
      SetTxt(LBL_CLOSE_T, g_allCloseTime>0
             ? "Close: "+TimeToStr(g_allCloseTime+ofs, TIME_DATE|TIME_MINUTES)
             : "Close: --");
   }

   UpdateSlots();

   // TP/SL Lineボタンのラベルを状態に合わせて更新
   if(ObjectFind(0, BTN_LINES) >= 0)
   {
      string ltxt = g_linesShown ? "TP/SL Line: ON " : "TP/SL Line: OFF";
      color  lbg  = g_linesShown ? C'20,70,20'       : C'50,50,70';
      color  lfg  = g_linesShown ? C'100,255,100'     : C'150,150,180';
      ObjectSetString (0, BTN_LINES, OBJPROP_TEXT,    ltxt);
      ObjectSetInteger(0, BTN_LINES, OBJPROP_BGCOLOR, lbg);
      ObjectSetInteger(0, BTN_LINES, OBJPROP_COLOR,   lfg);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
void DetectClosedPositions()
{
   double f = (_Digits==3||_Digits==5) ? 10.0 : 1.0;

   int curTickets[MAX_HIST];
   int curCount=0;
   ArrayInitialize(curTickets,-1);
   for(int i=0;i<OrdersTotal()&&curCount<MAX_HIST;i++)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType()!=OP_BUY&&OrderType()!=OP_SELL) continue;
      curTickets[curCount++]=OrderTicket();
   }

   if(!g_hadPosition && curCount>0)
   {
      datetime earliest=0;
      for(int i=0;i<OrdersTotal();i++)
      {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
         if(OrderType()!=OP_BUY&&OrderType()!=OP_SELL) continue;
         if(earliest==0||OrderOpenTime()<earliest) earliest=OrderOpenTime();
      }
      g_firstOpenTime=earliest;
      g_hadPosition=true;
      g_allCloseTime=0;
      // 初めてポジションを持ったとき：自動表示が有効ならライン作成
      if(AutoShowLines && !g_linesShown) CreateTPSLLines();
   }

   for(int p=0;p<g_prevCount;p++)
   {
      bool found=false;
      for(int c=0;c<curCount;c++)
         if(g_prevTickets[p]==curTickets[c]){found=true;break;}
      if(!found && OrderSelect(g_prevTickets[p],SELECT_BY_TICKET,MODE_HISTORY))
      {
         double pips=0;
         if(OrderType()==OP_BUY)
            pips=(OrderClosePrice()-OrderOpenPrice())/(_Point*f);
         else if(OrderType()==OP_SELL)
            pips=(OrderOpenPrice()-OrderClosePrice())/(_Point*f);
         g_closedPips+=pips;
      }
   }

   if(g_hadPosition&&g_prevCount>0&&curCount==0)
   {
      g_allCloseTime=TimeCurrent();
      // 全決済時にラインを削除
      if(g_linesShown) RemoveTPSLLines();
   }

   g_prevCount=curCount;
   ArrayCopy(g_prevTickets,curTickets);
}

//+------------------------------------------------------------------+
double CalcLivePips()
{
   double tot=0,f=(_Digits==3||_Digits==5)?10.0:1.0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType()==OP_BUY)  tot+=(Bid-OrderOpenPrice())/(_Point*f);
      if(OrderType()==OP_SELL) tot+=(OrderOpenPrice()-Ask)/(_Point*f);
   }
   return tot;
}

void UpdateSlots()
{
   double f=(_Digits==3||_Digits==5)?10.0:1.0;
   int si=0;
   for(int i=0;i<OrdersTotal()&&si<MAX_POS;i++)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      int t=OrderType();
      if(t!=OP_BUY&&t!=OP_SELL) continue;
      double pips=(t==OP_BUY)?(Bid-OrderOpenPrice())/(_Point*f)
                             :(OrderOpenPrice()-Ask)/(_Point*f);
      if(ObjectFind(0,g_slotLbl[si])>=0)
      {
         SetTxt(g_slotLbl[si],StringFormat("%s  %.2fL  %+.1f pips",
                (t==OP_BUY?"BUY":"SELL"),OrderLots(),pips));
         ObjectSetInteger(0,g_slotLbl[si],OBJPROP_COLOR,
                          pips>=0?C'150,220,255':C'255,160,160');
      }
      si++;
   }
}

void CloseSlot(int si)
{
   int idx = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      int t = OrderType();
      if(t != OP_BUY && t != OP_SELL) continue;
      if(idx == si)
      {
         RefreshRates();
         double closePrice = (t == OP_BUY) ? MarketInfo(OrderSymbol(), MODE_BID)
                                           : MarketInfo(OrderSymbol(), MODE_ASK);
         if(!OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, clrNONE))
            Print("CloseSlot Error [#", OrderTicket(), "]: ", GetLastError());
         return;
      }
      idx++;
   }
}

int CountPositions()
{
   int cnt=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType()==OP_BUY||OrderType()==OP_SELL) cnt++;
   }
   return cnt;
}

void CloseAll()
{
   RefreshRates();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      int t = OrderType();
      if(t != OP_BUY && t != OP_SELL) continue;
      double closePrice = (t == OP_BUY) ? MarketInfo(OrderSymbol(), MODE_BID)
                                        : MarketInfo(OrderSymbol(), MODE_ASK);
      if(!OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, clrNONE))
         Print("CloseAll Error [#", OrderTicket(), "]: ", GetLastError());
   }
}

void ReadLot()
{
   double v=StrToDouble(ObjectGetString(0,EDT_LOT,OBJPROP_TEXT));
   double mn=MarketInfo(Symbol(),MODE_MINLOT);
   double mx=MarketInfo(Symbol(),MODE_MAXLOT);
   double st=MarketInfo(Symbol(),MODE_LOTSTEP);
   int dc=(st>=1.0)?0:(st>=0.1)?1:2;
   g_lot=MathMax(mn,MathMin(mx,NormalizeDouble(MathRound(v/st)*st,dc)));
   ObjectSetString(0,EDT_LOT,OBJPROP_TEXT,DoubleToStr(g_lot,2));
   ChartRedraw();
}

void PlaceOrder(int type)
{
   RefreshRates();
   double p    = (type==OP_BUY) ? Ask : Bid;
   double pip  = _Point * ((_Digits==3||_Digits==5) ? 10.0 : 1.0);
   double sl   = 0, tp = 0;

   if(UseAutoTPSL)
   {
      if(type==OP_BUY)
      {
         tp = NormalizeDouble(p + TakeProfitPips * pip, _Digits);
         sl = NormalizeDouble(p - StopLossPips  * pip, _Digits);
      }
      else
      {
         tp = NormalizeDouble(p - TakeProfitPips * pip, _Digits);
         sl = NormalizeDouble(p + StopLossPips  * pip, _Digits);
      }
   }

   int tk = OrderSend(Symbol(), type, g_lot, p, Slippage, sl, tp,
                      type==OP_BUY ? "Panel BUY" : "Panel SELL",
                      MagicNumber, 0,
                      type==OP_BUY ? clrDodgerBlue : clrCrimson);
   if(tk < 0)
      Print("OrderSend Error:", GetLastError());
   else if(UseAutoTPSL)
      Print(StringFormat("nico-panel: %s 発注 TP=%.5f SL=%.5f",
            type==OP_BUY?"BUY":"SELL", tp, sl));
}

void ResetBtn(string n){ObjectSetInteger(0,n,OBJPROP_STATE,false);}
void SetTxt(string n,string t){ObjectSetString(0,n,OBJPROP_TEXT,t);}

//+------------------------------------------------------------------+
//| ボタン状態ポーリング（CHARTEVENT_OBJECT_CLICKが届かない場合の補完）|
//+------------------------------------------------------------------+
void CheckPanelButtons()
{
   // BUY / SELL
   if(ObjectGetInteger(0, BTN_BUY,  OBJPROP_STATE)){ ReadLot(); PlaceOrder(OP_BUY);  ResetBtn(BTN_BUY);  }
   if(ObjectGetInteger(0, BTN_SELL, OBJPROP_STATE)){ ReadLot(); PlaceOrder(OP_SELL); ResetBtn(BTN_SELL); }

   // Close All（最重要）
   if(ObjectGetInteger(0, BTN_CLOSEALL, OBJPROP_STATE))
   {
      Print("nico-panel: CloseAll ボタン検知");
      CloseAll();
      ResetBtn(BTN_CLOSEALL);
   }

   // TP/SL Line トグル
   if(ObjectGetInteger(0, BTN_LINES, OBJPROP_STATE)){ ToggleLines();      ResetBtn(BTN_LINES); }

   // Reset Pips
   if(ObjectGetInteger(0, BTN_RESET, OBJPROP_STATE))
   {
      g_closedPips=0.0; g_firstOpenTime=0; g_allCloseTime=0; g_hadPosition=false;
      UpdateAll(); ResetBtn(BTN_RESET);
   }

   // 閉じる / Open
   if(ObjectGetInteger(0, BTN_CLOSE, OBJPROP_STATE)) Minimize();
   if(ObjectGetInteger(0, BTN_OPEN,  OBJPROP_STATE)) Restore();

   // 個別スロット × ボタン
   for(int i = 0; i < MAX_POS; i++)
      if(ObjectGetInteger(0, g_slotBtn[i], OBJPROP_STATE)){ CloseSlot(i); ResetBtn(g_slotBtn[i]); }
}

//+------------------------------------------------------------------+
//|  TP/SL ライン管理                                                  |
//+------------------------------------------------------------------+

// ラインを1本作成するヘルパー
void MkHLine(string name, double price, color clr, string label)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      LineWidth);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   true);   // 最初からドラッグ可能
   ObjectSetString (0, name, OBJPROP_TEXT,       label);
}

// 現在のポジションからTP/SL価格を取得してラインを作成・更新
void CreateTPSLLines()
{
   double pip = _Point * ((_Digits==3||_Digits==5) ? 10.0 : 1.0);
   double tp = 0, sl = 0;

   // まず既存ポジションのTP/SLを参照
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;
      if(tp == 0 && OrderTakeProfit() != 0) tp = OrderTakeProfit();
      if(sl == 0 && OrderStopLoss()   != 0) sl = OrderStopLoss();
      if(tp != 0 && sl != 0) break;
   }

   // ポジションにTP/SLが設定されていない場合はデフォルト pips で配置
   if(tp == 0)
   {
      double mid = (Ask + Bid) / 2.0;
      tp = NormalizeDouble(mid + TakeProfitPips * pip, _Digits);
   }
   if(sl == 0)
   {
      double mid = (Ask + Bid) / 2.0;
      sl = NormalizeDouble(mid - StopLossPips * pip, _Digits);
   }

   MkHLine(LINE_TP, tp, LineTPColor,
           StringFormat("TP  %.5f  (drag to move all)", tp));
   MkHLine(LINE_SL, sl, LineSLColor,
           StringFormat("SL  %.5f  (drag to move all)", sl));

   g_lastLineTP = tp;
   g_lastLineSL = sl;
   g_linesShown = true;
   if(g_open) BuildAll();   // ボタン表示を更新
   Print(StringFormat("nico-panel: TP/SLライン表示 TP=%.5f SL=%.5f", tp, sl));
}

// ラインを削除
void RemoveTPSLLines()
{
   ObjectDelete(0, LINE_TP);
   ObjectDelete(0, LINE_SL);
   g_linesShown = false;
   g_lastLineTP = 0;
   g_lastLineSL = 0;
   if(g_open) BuildAll();
}

// ボタンでON/OFFトグル
void ToggleLines()
{
   if(g_linesShown) RemoveTPSLLines();
   else
   {
      if(CountPositions() > 0) CreateTPSLLines();
      else
      {
         // ポジションなし：現在値から仮配置
         double pip = _Point * ((_Digits==3||_Digits==5) ? 10.0 : 1.0);
         double mid = (Ask + Bid) / 2.0;
         double tp  = NormalizeDouble(mid + TakeProfitPips * pip, _Digits);
         double sl  = NormalizeDouble(mid - StopLossPips   * pip, _Digits);
         MkHLine(LINE_TP, tp, LineTPColor,
                 StringFormat("TP  %.5f  (drag to move all)", tp));
         MkHLine(LINE_SL, sl, LineSLColor,
                 StringFormat("SL  %.5f  (drag to move all)", sl));
         g_lastLineTP = tp;
         g_lastLineSL = sl;
         g_linesShown = true;
         if(g_open) BuildAll();
      }
   }
}

// ライン上の現在価格を確実に取得
double GetLinePrice(string name)
{
   if(ObjectFind(0, name) < 0) return 0;
   return ObjectGetDouble(0, name, OBJPROP_PRICE1);
}

// ラインが動いていないか確認し、動いていれば全ポジションに反映
void CheckAndApplyLines()
{
   if(!g_linesShown) return;

   double tp = NormalizeDouble(GetLinePrice(LINE_TP), _Digits);
   double sl = NormalizeDouble(GetLinePrice(LINE_SL), _Digits);

   if(tp != 0 && MathAbs(tp - g_lastLineTP) >= _Point)
   {
      Print(StringFormat("nico-panel: TPライン変化 %.5f → %.5f", g_lastLineTP, tp));
      g_lastLineTP = tp;
      ApplyTPLine(tp);
   }
   if(sl != 0 && MathAbs(sl - g_lastLineSL) >= _Point)
   {
      Print(StringFormat("nico-panel: SLライン変化 %.5f → %.5f", g_lastLineSL, sl));
      g_lastLineSL = sl;
      ApplySLLine(sl);
   }
}

// TPを全ポジションに適用
void ApplyTPLine(double tp)
{
   if(ObjectFind(0, LINE_TP) >= 0)
      ObjectSetString(0, LINE_TP, OBJPROP_TEXT,
                      StringFormat("TP  %.5f  (drag to move all)", tp));
   int cnt = 0, modified = 0, errors = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      cnt++;
      double sl = OrderStopLoss();
      Print(StringFormat("nico-panel: TP変更 #%d  %.5f→%.5f", OrderTicket(), OrderTakeProfit(), tp));
      if(OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, clrNONE))
         modified++;
      else
      {
         errors++;
         Print(StringFormat("nico-panel: TP変更失敗 #%d Error=%d", OrderTicket(), GetLastError()));
      }
   }
   Print(StringFormat("nico-panel: TP一括 %.5f | 対象=%d 成功=%d 失敗=%d", tp, cnt, modified, errors));
}

// SLを全ポジションに適用
void ApplySLLine(double sl)
{
   if(ObjectFind(0, LINE_SL) >= 0)
      ObjectSetString(0, LINE_SL, OBJPROP_TEXT,
                      StringFormat("SL  %.5f  (drag to move all)", sl));
   int cnt = 0, modified = 0, errors = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      cnt++;
      double tp = OrderTakeProfit();
      Print(StringFormat("nico-panel: SL変更 #%d  %.5f→%.5f", OrderTicket(), OrderStopLoss(), sl));
      if(OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, clrNONE))
         modified++;
      else
      {
         errors++;
         Print(StringFormat("nico-panel: SL変更失敗 #%d Error=%d", OrderTicket(), GetLastError()));
      }
   }
   Print(StringFormat("nico-panel: SL一括 %.5f | 対象=%d 成功=%d 失敗=%d", sl, cnt, modified, errors));
}

//+------------------------------------------------------------------+
void MkBg(string n,int x,int y,int w,int h,color bg,color bd)
{
   if(ObjectFind(0,n)>=0) ObjectDelete(0,n);
   ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,       w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,       h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bd);
   ObjectSetInteger(0,n,OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0,n,OBJPROP_BACK,        false);
}

void MkBtn(string n,string txt,int x,int y,int w,int h,
           color bg,color fg,int fs,string font)
{
   if(ObjectFind(0,n)>=0) ObjectDelete(0,n);
   ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,        w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,        h);
   ObjectSetString (0,n,OBJPROP_TEXT,         txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,        fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR, C'60,60,60');
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,     fs);
   ObjectSetString (0,n,OBJPROP_FONT,         font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,   false);
}

void MkEdit(string n,string txt,int x,int y,int w,int h,
            color bg,color fg,color bd,int fs)
{
   if(ObjectFind(0,n)>=0) ObjectDelete(0,n);
   ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,        w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,        h);
   ObjectSetString (0,n,OBJPROP_TEXT,         txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,        fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR, bd);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,     fs);
   ObjectSetString (0,n,OBJPROP_FONT,         "Arial Bold");
   ObjectSetInteger(0,n,OBJPROP_ALIGN,        ALIGN_CENTER);
   ObjectSetInteger(0,n,OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,   false);
}

void MkLabel(string n,string txt,int x,int y,color clr,int fs,string font)
{
   if(ObjectFind(0,n)>=0) ObjectDelete(0,n);
   ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,  y);
   ObjectSetString (0,n,OBJPROP_TEXT,       txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,      clr);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,   fs);
   ObjectSetString (0,n,OBJPROP_FONT,       font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE, false);
}

void MkCenterLabel(string n,string txt,int x,int y,int w,int h,
                   color clr,color bg,int fs)
{
   if(ObjectFind(0,n)>=0) ObjectDelete(0,n);
   ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,        w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,        h);
   ObjectSetString (0,n,OBJPROP_TEXT,         txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,        clr);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,     fs);
   ObjectSetString (0,n,OBJPROP_FONT,         "Arial Bold");
   ObjectSetInteger(0,n,OBJPROP_ALIGN,        ALIGN_CENTER);
   ObjectSetInteger(0,n,OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0,n,OBJPROP_READONLY,     true);
}
//+------------------------------------------------------------------+