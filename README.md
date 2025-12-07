# Cloud-IoT-5G-PV-MPPT✅ داشبورد جامع برای کل سیستم Cloud–IoT–5G–PV–MPPT
این داشبورد باید 9 بخش اصلی داشته باشد:
________________________________________
Header   (وضعیت کلی سیستم)
این بالا، در تمام صفحه باشد.
نمایش بده:
•	🔹 وضعیت سیستم:
o	🟢 Online / 🔴 Offline
•	🔹 زمان شبیه‌سازی یا زمان عملیاتی
•	🔹 مدل فعال:
o	Cloud-based AI-Driven MPPT System
•	🔹 سناریوی فعال:
o	TestID + توضیح متنی (Normal / MPPT Fault / COMM Fault / Global Fault)
•	🔹 Node فعال:
o	Selected Node
________________________________________
 System Overview  نمای کلی سیستم (کاشی‌های خلاصه)
۴ یا ۵ کاشی بزرگ بالای صفحه:
🔹 PV & Power
•	Power
•	PowerAI
•	Efficiency Index (EffIdx)
•	نمودارهای توان
________________________________________
🔹 MPPT Layer
•	الگوریتم فعال (ANN / SVM / P&O)
•	Mode_out
•	MPPT Cost (Final_Cost یا Final_Cost_AI)
________________________________________
🔹 IoT Network
•	Delay_Node1
•	PacketLoss_Node1
•	SNR_Node1
________________________________________
🔹 5G Network
•	Delay5G_NodeX
•	SNR_5G
•	MCS
•	Throughput
________________________________________
🔹 Cloud Intelligence
•	QoSIdx
•	PerfScore
•	FaultCode
•	Anomaly
________________________________________
 Communication Layer Panel  بخش اختصاصی شبکه
این صفحه برای مهندس شبکه است:
بخش IoT:
•	Delay
•	Packet Loss
•	SNR
•	Energy Efficiency Node
•	Throughput Node
•	Retry Rate
بخش 5G:
•	Delay 5G
•	MCS
•	SNR 5G
•	Tx Power
•	Spectral Efficiency
نمایش نمودار:
•	Delay vs Time
•	SNR vs Time
•	PacketLoss vs Time
•	Throughput vs Time
________________________________________
-MPPT & Control Panel  بخش کنترل MPPT
نمایش:
•	MPPT Algorithm (Active)
•	Efficiency over time
•	Power Tracking
کنترل:
•	انتخاب دستی الگوریتم (Manual Override)
•	تغییر TestID
•	استارت / توقف شبیه‌سازی
•	Reset مدل
________________________________________
Fault & Anomaly Center  مرکز تشخیص خطا
نمایش بده:
•	Fault Timeline
•	Fault Percentage Pie Chart
•	Anomaly Gauge
•	لیست رخدادها:
Time	Node	Fault	Algorithm	QoS	Efficiency
________________________________________
 Cloud Analytics Panel  تحلیل مرکزی Cloud
نمایش:
•	Performance Score
•	QoS Index
•	Stability Index
•	Efficiency Index
نمودار ترکیبی:
•	Radar Chart عملکرد سیستم
•	Scatter Fault vs QoS vs Efficiency
________________________________________
 KPI Summary & Reports  گزارش‌گیری حرفه‌ای
اینجا همان فایل Excel باید لینک شود:
•	جدول نتایج ۴ تست
•	Bar chart:
o	Efficiency Mean
o	QoS Mean
o	Anomaly Mean
•	Stacked Fault Chart
دکمه:
•	Export Report
•	Download Results
________________________________________
Sensitivity & What-If Panel
نمایش:
•	Heatmap آستانه‌ها
•	False Alarm Rate
•	Detection Rate
کنترل:
•	Slider برای Eff_thr
•	Slider برای QoS_thr
•	Slider برای Fault_thr
________________________________________
تنظیمات سیستم (Settings Panel)
•	انتخاب Sampling Rate
•	انتخاب Mode Cloud (Learning / Static)
•	Reset logs
•	Clear database



