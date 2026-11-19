/// 받침 유무에 맞는 조사를 붙인다. 예: josa('한식', '을', '를') → '한식을'.
String josa(String word, String withBatchim, String withoutBatchim) {
  if (word.isEmpty) return word;
  final code = word.codeUnitAt(word.length - 1);
  final isHangul = code >= 0xAC00 && code <= 0xD7A3;
  final jong = isHangul ? (code - 0xAC00) % 28 : 0;
  // '으로/로'는 ㄹ 받침 뒤에도 '로'를 쓴다. (서울로)
  if (withBatchim == '으로' && jong == 8) return '$word$withoutBatchim';
  return '$word${jong != 0 ? withBatchim : withoutBatchim}';
}
