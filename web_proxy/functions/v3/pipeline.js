// Cloudflare Pages Function served at /v3/pipeline on the app's own domain.
import { handlePipeline } from '../../src/proxy.js';

export const onRequest = ({ request, env }) => handlePipeline(request, env);
