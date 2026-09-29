/// 「呷飽來動」全 App 在地化親切、微幽默文案常數庫
class AppStrings {
  AppStrings._();

  static const String appName = '呷飽來動';
  static const String appSlogan = '好料放心呷，吃飽才有力氣練！';

  // API Key 設定頁文案
  static const String apiKeyTitle = 'Gemini API 金鑰設定';
  static const String apiKeySubtitle = '自己提供金鑰最安心，隱私完全留在您的手機裡，絕不上傳他人伺服器。';
  static const String apiKeyInputLabel = 'Gemini API Key';
  static const String apiKeyInputHint = '請貼上 Gemini API 金鑰 (AQ. 或 AIza 開頭)...';
  static const String testConnectionBtn = '測試連線並儲存';
  static const String testingConnection = '連線測試中，正呼叫 Gemini 營養師...';
  static const String apiKeySavedSuccess = '連線成功！Gemini 營養師已就位，今天吃了啥好料？';
  static const String apiKeyInvalidError = '哎呀！這個 API Key 好像走錯棚了，請確認是否有開通 Gemini API 權限喔！';
  static const String serviceNotEnabledError = '找不到這個模型或服務未開通！請至 Google AI Studio 確認專案是否已啟用 Gemini API 喔！';
  static const String quotaExceededError = '這個 API Key 今天的免費額度稍微用光了！請稍候再試或換一組金鑰喔！';
  static const String apiKeyEmptyError = '金鑰不能空空的啦！請先輸入您的 Gemini API Key。';
  static const String networkError = '網路好像在偷懶喔！請檢查您的網路連線再試一次。';
  static const String unknownError = '連線發生小狀況，請稍後再試試看！';
  static const String clearKeyBtn = '刪除這組金鑰';
  static const String keyStoredSecurely = '金鑰已安全保存在手機中';
  static const String clearKeyDialogTitle = '刪除這組金鑰？';
  static const String clearKeyDialogMessage = '確定要從手機中刪除這組金鑰嗎？刪除後需要重新輸入，才能使用拍照算熱量功能喔！';
  static const String clearKeyConfirmBtn = '確定刪除';
  static const String clearKeyCancelBtn = '先不要';

  // 拍照辨識與分析文案
  static const String analyzingFood = '正在幫你算這頓有多補... 請稍候！';
  static const String foodNotDetected = '咦？照片裡好像看不到食物耶！請拍清楚美味的一餐喔。';
  static const String analysisFailed = '辨識過程遇到小亂流，換張角度再試試看吧！';

  // 營養素標籤
  static const String calories = '總熱量';
  static const String protein = '蛋白質';
  static const String carbs = '碳水化合物';
  static const String fat = '脂肪';
  static const String servingSize = '份量預估';
  static const String coachTip = '教練真心話';
}
