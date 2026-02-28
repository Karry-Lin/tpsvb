import 'package:audioplayers/audioplayers.dart';

/// 統一管理 App 音效的服務
class AudioService {
  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _searchingPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();

  AudioService() {
    // 搜尋中音效設定為循環
    _searchingPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// 通用點擊音效（按鈕、套用篩選、點開時段詳情、點開預約連結）
  Future<void> playButton() async {
    await _buttonPlayer.stop();
    await _buttonPlayer.play(AssetSource('sounds/button.mp3'));
  }

  /// 開始搜尋：循環播放搜尋音效
  Future<void> startSearching() async {
    await _searchingPlayer.stop();
    await _searchingPlayer.play(AssetSource('sounds/searching.mp3'));
  }

  /// 停止搜尋音效
  Future<void> stopSearching() async {
    await _searchingPlayer.stop();
  }

  /// 查詢完成音效
  Future<void> playSuccess() async {
    await _searchingPlayer.stop();
    await _successPlayer.stop();
    await _successPlayer.play(AssetSource('sounds/success.mp3'));
  }

  /// 釋放資源
  void dispose() {
    _buttonPlayer.dispose();
    _searchingPlayer.dispose();
    _successPlayer.dispose();
  }
}
