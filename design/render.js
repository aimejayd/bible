// Renders design/mark.svg into the Android launcher icons, splash images and
// the in-app logo. Run from the repo root: node design/render.js
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..');
const mark = fs.readFileSync(path.join(__dirname, 'mark.svg'), 'utf8');
const res = path.join(root, 'android/app/src/main/res');
const GREEN = '#1E4D42';
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };

// size: output px; scale: mark size as a share of the canvas; bg: fill; radius: corner share
function html(size, scale, bg, radius) {
  const m = Math.round(size * scale);
  return `<html><body style="margin:0;background:transparent">
    <div style="width:${size}px;height:${size}px;display:flex;align-items:center;justify-content:center;
      background:${bg || 'transparent'};border-radius:${(radius || 0) * size}px;overflow:hidden">
      <div style="width:${m}px;height:${m}px">${mark.replace('<svg ', `<svg width="${m}" height="${m}" `)}</div>
    </div></body></html>`;
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  async function shot(file, size, scale, bg, radius) {
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(html(size, scale, bg, radius));
    fs.mkdirSync(path.dirname(file), { recursive: true });
    await page.screenshot({ path: file, omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
  }
  for (const [d, f] of Object.entries(densities)) {
    await shot(`${res}/mipmap-${d}/ic_launcher.png`, Math.round(48 * f), 0.78, GREEN, 0.22);
    await shot(`${res}/mipmap-${d}/ic_launcher_foreground.png`, Math.round(108 * f), 0.56);
    await shot(`${res}/drawable-${d}/splash_logo.png`, Math.round(128 * f), 1);
  }
  await shot(`${res}/drawable-xxxhdpi/splash_icon.png`, 288 * 4, 0.62);
  await shot(path.join(root, 'assets/brand/mark.png'), 512, 1);
  await shot(path.join(__dirname, 'play_store_icon.png'), 512, 0.78, GREEN, 0);
  await browser.close();
  console.log('rendered');
})();
