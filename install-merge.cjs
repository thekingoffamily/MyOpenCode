const fs = require('fs');
const [, , srcPath, dstPath] = process.argv;

const src = JSON.parse(fs.readFileSync(srcPath, 'utf8'));
let dst = {};
if (fs.existsSync(dstPath)) {
  try {
    dst = JSON.parse(fs.readFileSync(dstPath, 'utf8'));
  } catch (e) {
    console.error('WARN: existing opencode.json is not valid JSON, overwriting. ' + e.message);
    dst = {};
  }
}

dst.provider = Object.assign({}, dst.provider, src.provider);
if (!dst.model) dst.model = src.model;
if (!dst.small_model) dst.small_model = src.small_model;
if (!dst['$schema']) dst['$schema'] = src['$schema'];

const tmp = dstPath + '.tmp';
fs.writeFileSync(tmp, JSON.stringify(dst, null, 2));
fs.renameSync(tmp, dstPath);
console.log('Merged aiTunnel provider into ' + dstPath);