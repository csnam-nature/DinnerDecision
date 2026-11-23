/**
 * 개인정보처리방침 페이지 (GET /privacy). Play 스토어·App Store에 이 주소를 적는다.
 * 앱이 실제로 하는 일과 맞아야 한다. 동작을 바꾸면 이 내용도 같이 고친다.
 *
 */
export const PRIVACY_VERSION = '2026-11-23';
const OPERATOR = 'naturetec';
const CONTACT = 'dontforgetcosmos@gmail.com';

export const PRIVACY_HTML = `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>개인정보처리방침 · 오늘 저녁 뭐 먹지</title>
<style>
  body { font-family: -apple-system, 'Pretendard', 'Apple SD Gothic Neo', 'Malgun Gothic', sans-serif;
         max-width: 720px; margin: 0 auto; padding: 24px 20px 64px; line-height: 1.7; color: #212529; }
  h1 { font-size: 1.5rem; margin-bottom: 4px; }
  h2 { font-size: 1.1rem; margin-top: 2em; border-bottom: 1px solid #e9ecef; padding-bottom: 4px; }
  table { border-collapse: collapse; width: 100%; font-size: .95rem; }
  th, td { border: 1px solid #dee2e6; padding: 6px 8px; text-align: left; vertical-align: top; }
  th { background: #f8f9fa; }
  .muted { color: #6c757d; font-size: .9rem; }
</style>
</head>
<body>
<h1>개인정보처리방침</h1>
<p class="muted">오늘 저녁 뭐 먹지 · 시행일 ${PRIVACY_VERSION}</p>

<p>${OPERATOR}(이하 "운영자")는 「오늘 저녁 뭐 먹지」 앱(이하 "앱")을 이용하는 분의 개인정보를 소중히 다룹니다.
앱은 <strong>회원가입이 없고</strong>, 식사 기록과 사진은 <strong>이용자의 휴대폰에만</strong> 저장합니다.</p>

<h2>1. 처리하는 정보와 목적</h2>
<table>
<tr><th>정보</th><th>목적</th><th>어디에, 얼마나</th></tr>
<tr><td>위치(위도·경도)</td><td>주변 음식점 찾기, 동 이름 표시, 날씨 조회</td>
<td>앱이 약 100m 단위로 줄인 값을 운영자 서버로 보냅니다. 서버는 외부 서비스에 조회한 뒤 <strong>위치를 저장하거나 기록하지 않습니다.</strong>
정확한 위치는 휴대폰 안에서 거리 계산에만 씁니다.</td></tr>
<tr><td>위치 검색어</td><td>위치를 직접 정할 때 주소·장소 검색</td><td>서버가 외부 서비스에 조회만 하고 저장하지 않습니다.</td></tr>
<tr><td>식사 기록(날짜, 식당, 메뉴, 별점, 메모, 당시 날씨), 사진, 설정, 숨긴 식당</td>
<td>기록·달력·추천</td><td><strong>이용자 휴대폰에만</strong> 저장합니다. 앱을 지우면 함께 지워집니다. 운영자는 볼 수 없습니다.</td></tr>
<tr><td>접속 IP 주소</td><td>과도한 호출 막기</td><td>IP를 그대로 저장하지 않고 변환(해시)한 값으로 1분 동안의 호출 횟수만 세며, 하루 안에 지웁니다.</td></tr>
<tr><td>오류 정보(오류 내용, 코드 위치, 기기 모델, OS 버전, 앱 버전, 앱 설치 식별자)</td>
<td>앱 오류 찾기·고치기</td><td>Google Firebase Crashlytics에 보관되며 보관 기간은 Google 정책을 따릅니다(기본 90일). 위치·기록·사진은 포함하지 않습니다.</td></tr>
<tr><td>앱 인증 정보(기기 무결성 확인 결과)</td><td>정상 앱의 요청인지 확인(부정 이용 방지)</td>
<td>Google Firebase App Check, Google Play Integrity / Apple App Attest가 처리합니다. 운영자 서버는 확인 결과만 쓰고 저장하지 않습니다.</td></tr>
</table>

<h2>2. 휴대폰 권한</h2>
<ul>
<li><strong>위치(앱 사용 중):</strong> 주변 음식점 찾기. 허용하지 않아도 위치를 직접 검색해 쓸 수 있습니다.</li>
<li><strong>카메라·사진:</strong> 식사 기록에 사진을 붙일 때만. 사진은 휴대폰에만 저장합니다.</li>
</ul>

<h2>3. 외부 서비스와 처리 위탁</h2>
<p>운영자는 개인정보를 판매하거나 광고에 쓰지 않습니다. 앱을 운영하기 위해 아래 서비스를 이용합니다.</p>
<table>
<tr><th>서비스</th><th>하는 일</th><th>전달되는 정보</th></tr>
<tr><td>Cloudflare (서버 운영)</td><td>운영자 서버 실행</td><td>요청 내용(줄인 위치), 접속 IP</td></tr>
<tr><td>카카오 로컬 API</td><td>음식점·동 이름·주소 검색</td><td>운영자 서버가 줄인 위치·검색어로 조회 (이용자 IP는 전달되지 않음)</td></tr>
<tr><td>기상청 단기예보 (공공데이터포털)</td><td>날씨</td><td>운영자 서버가 약 5km 격자 번호로 조회</td></tr>
<tr><td>네이버 지도</td><td>앱 안 지도 표시</td><td>지도를 보여주는 영역 정보(지도 앱·SDK가 직접 처리)</td></tr>
<tr><td>Google Firebase</td><td>오류 수집, 앱 인증</td><td>1장의 오류 정보·앱 인증 정보</td></tr>
</table>
<p class="muted">Cloudflare, Google의 서버는 국외에 있을 수 있습니다. 상세는 각 회사의 개인정보처리방침을 따릅니다.</p>

<h2>4. 백업 파일</h2>
<p>설정 › 백업·복원에서 만든 백업 파일(기록·사진 포함)은 이용자가 고른 곳(드라이브, 메신저 등)에 이용자가 직접 보관합니다. 운영자에게 전송되지 않습니다.</p>

<h2>5. 보관과 파기</h2>
<ul>
<li>휴대폰의 기록·사진: 이용자가 지우거나 앱을 삭제하면 지워집니다.</li>
<li>서버의 음식점·날씨 캐시: 개인정보가 아닌, 위치와 무관한 지역 칸 단위의 공개 정보입니다. 24시간(날씨 20분)이 지나면 쓰지 않고 하루 한 번 지웁니다.</li>
<li>호출 제한 기록: 하루 안에 지웁니다.</li>
</ul>

<h2>6. 이용자의 권리</h2>
<p>운영자 서버에는 이용자를 알아볼 수 있는 정보가 저장되지 않으므로, 기록의 열람·정정·삭제는 앱에서 직접 할 수 있습니다.
오류 정보 삭제 등 문의는 아래 연락처로 해 주세요.</p>

<h2>7. 만 14세 미만</h2>
<p>앱은 만 14세 미만 아동을 대상으로 하지 않습니다.</p>

<h2>8. 안전 조치</h2>
<p>서버와의 통신은 암호화(HTTPS)하고, 외부 서비스 키는 서버에만 보관하며, 정상 앱의 요청만 받도록 앱 인증을 사용합니다.</p>

<h2>9. 개인정보 보호책임자·문의</h2>
<p>${OPERATOR} · <a href="mailto:${CONTACT}">${CONTACT}</a></p>

<h2>10. 변경</h2>
<p>이 방침을 바꾸면 이 페이지와 앱 업데이트 안내로 알립니다.</p>
</body>
</html>`;
