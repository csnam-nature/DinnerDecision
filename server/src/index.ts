import { handleRequest } from './app';
import type { Env } from './env';
import { purgeExpired } from './lib/cellStore';

// Workers 진입점. 이 파일에서는 default 외에 export 하지 않는다 (workerd가 진입점으로 착각함).
export default {
  fetch: (request, env) => handleRequest(request, env, { nowMs: Date.now }),
  scheduled: async (_controller, env) => {
    await purgeExpired(env.DB, Date.now());
  },
} satisfies ExportedHandler<Env>;
