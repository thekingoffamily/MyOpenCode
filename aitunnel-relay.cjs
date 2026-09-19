// Local forwarding proxy for opencode on hosts without global IPv6.
// opencode talks plain HTTP to 127.0.0.1:8787/v1; this proxy forwards to
// https://api.aitunnel.ru/v1 (node runs IPv4, which works everywhere).
//
// Usage:  AITUNNEL_RELAY_PORT=8787 node aitunnel-relay.cjs
// Health: curl http://127.0.0.1:8787/x   -> 200 "ok"
// Logs:   /tmp/relay.log
const { createServer } = require('http');
const fs = require('fs');

const PORT = Number(process.env.AITUNNEL_RELAY_PORT || 8787);
const TARGET = process.env.AITUNNEL_RELAY_TARGET || 'api.aitunnel.ru';
const LOG = '/tmp/relay.log';

function log(line) {
  try {
    fs.appendFileSync(LOG, new Date().toISOString() + ' ' + line + '\n');
  } catch (_) {
    /* ignore */
  }
}

createServer(async (req, res) => {
  const auth = req.headers && req.headers.authorization;
  log(req.method + ' ' + req.url + ' auth=' + (auth ? 'YES' : 'NO'));

  if (req.url === '/x') {
    res.writeHead(200, { 'content-type': 'text/plain' });
    res.end('ok');
    return;
  }

  const headers = { ...req.headers };
  delete headers.host;
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const body = Buffer.concat(chunks);

  try {
    const up = await fetch('https://' + TARGET + req.url, {
      method: req.method,
      headers,
      body: req.method === 'GET' || req.method === 'HEAD' ? undefined : body,
      redirect: 'manual',
    });
    log('upstream ' + up.status + ' ' + req.url);
    res.writeHead(up.status, Object.fromEntries(up.headers.entries()));
    const reader = up.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      res.write(value);
    }
    res.end();
  } catch (e) {
    log('upstream ERROR ' + e.message);
    if (!res.headersSent) {
      res.writeHead(502, { 'content-type': 'text/plain' });
      res.end('relay error: ' + e.message);
    } else {
      res.end();
    }
  }
}).listen(PORT, '127.0.0.1', () => {
  log('relay up on ' + PORT);
});

process.on('uncaughtException', (e) => log('uncaught ' + e.message));