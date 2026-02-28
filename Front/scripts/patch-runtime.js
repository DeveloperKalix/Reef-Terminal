#!/usr/bin/env node
/**
 * Patches the Jac client runtime to use JavaScript's built-in Error instead of
 * Exception (which is not defined in browser JS). Run after `jac build`.
 * Patches both the source runtime and the built bundle in dist so the fix is
 * included in deployment.
 * Usage: node scripts/patch-runtime.js
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');

// 1. Patch source runtime (so future builds may pick it up if build uses it)
const runtimePath = path.join(root, '.jac/client/compiled/client_runtime.js');
if (fs.existsSync(runtimePath)) {
  let content = fs.readFileSync(runtimePath, 'utf8');
  if (content.includes('new Exception(')) {
    content = content.replace(/throw new Exception\(/g, 'throw new Error(');
    fs.writeFileSync(runtimePath, content);
    console.log('patch-runtime: fixed Exception -> Error in client_runtime.js');
  }
}

// 2. Patch the built bundle(s) in dist (so deployed app has the fix)
const distDir = path.join(root, '.jac/client/dist');
if (!fs.existsSync(distDir)) {
  process.exit(0);
}
const files = fs.readdirSync(distDir).filter((f) => f.endsWith('.js') && f.startsWith('client.'));
for (const file of files) {
  const p = path.join(distDir, file);
  let content = fs.readFileSync(p, 'utf8');
  if (content.includes('new Exception(')) {
    content = content.replace(/new Exception\(/g, 'new Error(');
    fs.writeFileSync(p, content);
    console.log('patch-runtime: fixed Exception -> Error in', file);
  }
}
