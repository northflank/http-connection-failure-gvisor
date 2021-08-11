import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  vus: __ENV.VUS,
  duration: `${__ENV.DURATION}`,
  throw: true,
  noConnectionReuse: __ENV.REUSE_CONNECTION == "true" ? false : true,
  noVUConnectionReuse: __ENV.REUSE_CONNECTION == "true" ? false : true,
};

export default function() {
  http.get(`${__ENV.URL}`);
  sleep(0.5);
}