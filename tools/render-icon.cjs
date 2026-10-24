const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/youssef/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async () => {
  const dir = path.resolve(__dirname, '../assets/icon');
  const browser = await chromium.launch({channel:'msedge',headless:true});
  try {
    const page = await browser.newPage({viewport:{width:1024,height:1024},deviceScaleFactor:1});
    const svg = fs.readFileSync(path.join(dir,'knife.svg'),'utf8');
    await page.setContent(`<style>html,body{margin:0;background:transparent}svg{display:block;width:1024px;height:1024px}</style>${svg}`);
    await page.screenshot({path:path.join(dir,'foreground.png'),omitBackground:true});
    await page.addStyleTag({content:'html,body{background:white}'});
    await page.screenshot({path:path.join(dir,'app-icon.png')});
  } finally { await browser.close(); }
})();
