# วิธีรัน Tests และส่ง Log

## 🚀 วิธีรัน Tests

### **1. รัน Tests พร้อมบันทึก Log**

```bash
cd /Users/navathonlimamapar/Desktop/BCS-L/BCSLens-frontend
./test_runner.sh
```

**ผลลัพธ์:**
- ✅ Tests จะรันและบันทึก log ลงไฟล์อัตโนมัติ
- ✅ Log ไฟล์จะอยู่ที่: `test_logs/test_run_YYYYMMDD_HHMMSS.log`
- ✅ Error log จะอยู่ที่: `test_logs/test_errors_YYYYMMDD_HHMMSS.log`

---

## 📝 วิธีดู Log

### **Option 1: ใช้ Script (ง่ายที่สุด)**

```bash
./view_logs.sh
```

Script จะให้เลือก:
1. View full log - ดู log ทั้งหมด
2. View last 100 lines - ดู 100 บรรทัดสุดท้าย
3. View errors only - ดูเฉพาะ errors
4. View summary - ดูสรุปผลการทดสอบ

---

### **Option 2: ดู Log Manual**

```bash
# ดู log ล่าสุด
ls -lt test_logs/test_run_*.log | head -1

# ดู log ทั้งหมด
cat test_logs/test_run_YYYYMMDD_HHMMSS.log

# ดูเฉพาะ errors
cat test_logs/test_errors_YYYYMMDD_HHMMSS.log

# ดู 50 บรรทัดสุดท้าย
tail -n 50 test_logs/test_run_*.log
```

---

## 📤 วิธีส่ง Log ให้ดู

### **วิธีที่ 1: Copy Log File**

```bash
# 1. หา log file ล่าสุด
ls -lt test_logs/test_run_*.log | head -1

# 2. Copy เนื้อหา log
cat test_logs/test_run_YYYYMMDD_HHMMSS.log

# 3. Paste ใน chat
```

---

### **วิธีที่ 2: ส่งเฉพาะ Errors**

```bash
# ดูเฉพาะ errors
cat test_logs/test_errors_*.log

# หรือ
grep -i "error\|failed\|exception" test_logs/test_run_*.log
```

---

### **วิธีที่ 3: ส่ง Summary**

```bash
# ดูสรุปผลการทดสอบ
tail -n 100 test_logs/test_run_*.log | grep -E "(test|Test|passed|failed|All tests)"
```

---

## 🔍 ถ้ามี Error

### **1. ดู Error Log**

```bash
# ดู error log ล่าสุด
ls -t test_logs/test_errors_*.log | head -1 | xargs cat
```

### **2. ดู Full Log**

```bash
# ดู log ล่าสุดทั้งหมด
ls -t test_logs/test_run_*.log | head -1 | xargs cat
```

### **3. ดูเฉพาะส่วนที่ Error**

```bash
# หา error ใน log
grep -A 10 -B 10 "error\|Error\|ERROR\|failed\|Failed\|FAILED" test_logs/test_run_*.log
```

---

## 📋 ตัวอย่าง Output

### **เมื่อรันสำเร็จ:**
```
========================================
  BCS Lens - Automated Test Suite
========================================

📝 Log file: test_logs/test_run_20251106_143022.log
📝 Error log: test_logs/test_errors_20251106_143022.log

📦 Installing dependencies...
🧪 Running all tests...

✅ All tests passed!

📝 Full log saved to: test_logs/test_run_20251106_143022.log
```

### **เมื่อมี Error:**
```
❌ Some tests failed!

📝 Full error details saved to:
   - Log: test_logs/test_run_20251106_143022.log
   - Errors: test_logs/test_errors_20251106_143022.log

To view full log:
   cat test_logs/test_run_20251106_143022.log

To view only errors:
   cat test_logs/test_errors_20251106_143022.log
```

---

## 💡 Tips

1. **Log ไฟล์จะไม่หาย** - ทุกครั้งที่รันจะสร้าง log ไฟล์ใหม่
2. **Log เก่าจะเก็บไว้** - สามารถดูย้อนหลังได้
3. **Error log แยกต่างหาก** - ดู errors ได้ง่ายขึ้น
4. **Timestamp ในชื่อไฟล์** - รู้ว่า log ไหนรันเมื่อไหร่

---

## 🆘 Troubleshooting

### **Problem: Script ไม่รันได้**

```bash
# ให้ permission
chmod +x test_runner.sh
chmod +x view_logs.sh
```

### **Problem: Flutter ไม่เจอ**

```bash
# เช็ค Flutter
flutter --version

# ถ้าไม่มี ให้ติดตั้ง Flutter
# https://flutter.dev/docs/get-started/install
```

### **Problem: Log ยาวเกินไป**

```bash
# ดูเฉพาะส่วนที่สำคัญ
tail -n 100 test_logs/test_run_*.log

# หรือใช้ script
./view_logs.sh
# เลือก option 2 (View last 100 lines)
```

---

## 📞 ส่ง Log ให้ดู

**ถ้ามี error ให้ส่ง:**
1. Error log: `test_logs/test_errors_*.log`
2. หรือส่วน error จาก full log (50-100 บรรทัดสุดท้าย)

**คำสั่งที่ใช้:**
```bash
# ส่ง error log
cat test_logs/test_errors_*.log

# หรือส่งส่วน error จาก full log
tail -n 100 test_logs/test_run_*.log | grep -A 20 -B 5 "error\|Error\|ERROR\|failed\|Failed"
```

