/** wrangler.toml 의 [vars], D1, Secrets 로 들어오는 값. */
export interface Env {
  DB: D1Database;

  /** 카카오 REST API 키 (Secret). */
  KAKAO_REST_KEY: string;
  /** 공공데이터포털 기상청 단기예보 일반 인증키 (Secret). */
  KMA_SERVICE_KEY?: string;
  /** IP 해시용 소금값 (Secret, 선택). */
  RATE_LIMIT_SALT?: string;

  /** off: 검사 안 함 · monitor: 검사하고 로그만 · enforce: 실패하면 401 */
  APP_CHECK_MODE?: string;
  /** Firebase 프로젝트 번호 (숫자). App Check 토큰의 발급자·대상 확인에 사용. */
  FIREBASE_PROJECT_NUMBER?: string;
  /** 쉼표로 구분한 Firebase 앱 ID. 비어 있으면 같은 프로젝트의 앱은 모두 허용. */
  FIREBASE_APP_IDS?: string;

  /** 한 요청에서 카카오를 부를 수 있는 최대 횟수. 무료 요금제 상한(50) 아래로. */
  KAKAO_CALL_BUDGET?: string;
  /** IP 하나가 1분에 보낼 수 있는 요청 수. */
  RATE_LIMIT_PER_MINUTE?: string;
}

export function intVar(value: string | undefined, fallback: number): number {
  const n = Number.parseInt(value ?? '', 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}
