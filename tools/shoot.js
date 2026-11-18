#!/usr/bin/env node
/**
 * Take review screenshots of the skin on a running ILIAS (login, opened login form,
 * dashboard, repository, administration form, mobile width) and report every asset that
 * failed to load. Used to check the skin after a build or an ILIAS update.
 *
 * The README screenshot is made by tools/shoot-login.js, not by this script.
 *
 * Usage:
 *   ILIAS_PASSWORD=... node tools/shoot.js [out_dir]
 *
 * Environment:
 *   ILIAS_URL       Base URL (default http://localhost:8082)
 *   ILIAS_USER      Login name (default root)
 *   ILIAS_PASSWORD  Password — required, read from the environment only so it never
 *                   ends up in the repository or the shell history of a script call.
 *   CHROME_PATH     Chrome/Chromium binary (default: macOS Google Chrome)
 *
 * Requires puppeteer-core (not a dependency of the skin):
 *   npm install --prefix /tmp/pt puppeteer-core && NODE_PATH=/tmp/pt/node_modules node tools/shoot.js
 *
 * Exit code 1 if a page could not be opened or a skin asset failed to load.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');

const baseUrl = (process.env.ILIAS_URL || 'http://localhost:8082').replace(/\/+$/, '');
const user = process.env.ILIAS_USER || 'root';
const password = process.env.ILIAS_PASSWORD;
const chromePath = process.env.CHROME_PATH
  || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const outDir = path.resolve(process.argv[2] || 'screenshots');

const DESKTOP = { width: 1300, height: 800, deviceScaleFactor: 2 };
const MOBILE = { width: 390, height: 800, deviceScaleFactor: 2, isMobile: true };

async function main() {
  if (!password) {
    throw new Error('ILIAS_PASSWORD is not set');
  }
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await puppeteer.launch({ executablePath: chromePath, headless: 'new' });
  const failed = [];
  try {
    const page = await browser.newPage();
    // Collect every sub-resource that did not load: a 404 font or image is the most
    // common way a skin breaks, and it is invisible in a screenshot.
    page.on('response', (res) => {
      if (res.status() >= 400) {
        failed.push(`${res.status()} ${res.url()}`);
      }
    });
    page.on('requestfailed', (req) => failed.push(`FAILED ${req.url()}`));

    const shoot = async (name) => {
      // Web fonts load asynchronously; wait so headlines are not captured in the fallback face.
      await page.evaluate(() => document.fonts.ready);
      const file = path.join(outDir, `${name}.png`);
      await page.screenshot({ path: file });
      console.log(`  ${file}`);
    };
    const open = async (target) => {
      const res = await page.goto(`${baseUrl}/${target}`, { waitUntil: 'networkidle2', timeout: 60000 });
      if (!res || res.status() >= 400) {
        throw new Error(`${target} returned ${res ? res.status() : 'no response'}`);
      }
    };

    await page.setViewport(DESKTOP);
    await open('login.php?cmd=force_login&lang=de');
    await shoot('01-login');
    await page.setViewport(MOBILE);
    await shoot('02-login-mobile');

    // Switching the mobile emulation off reloads the page; open the login again so
    // the credentials are not typed into a document that is about to be replaced.
    await page.setViewport(DESKTOP);
    await open('login.php?cmd=force_login&lang=de');
    // The LUH login mask keeps the username/password form hidden until "Login ohne
    // WebSSO" is clicked (see components/ILIAS/Init/tpl.login.html).
    await page.click('#ilias_login_link');
    await page.waitForSelector('input[name="login_form/input_3/input_4"]', { visible: true, timeout: 10000 });
    await shoot('03-login-form-open');
    await page.type('input[name="login_form/input_3/input_4"]', user);
    await page.type('input[name="login_form/input_3/input_5"]', password);
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 60000 }),
      page.click('form[name="login_form"] button.btn-default, form[name="login_form"] .btn-primary'),
    ]);
    if (await page.$('input[name="login_form/input_3/input_5"]')) {
      throw new Error('login failed — still on the login page');
    }
    await shoot('04-dashboard');

    await open('goto.php/root/1');
    await shoot('05-repository');

    // A settings form shows headings, standard and primary buttons, tabs and inputs together.
    await open('ilias.php?baseClass=ilAdministrationGUI&ref_id=9&cmd=jump');
    await shoot('06-admin-form');

    await page.setViewport(MOBILE);
    await open('goto.php/root/1');
    await shoot('07-repository-mobile');
  } finally {
    await browser.close();
  }

  // Only assets the skin is responsible for make the run fail: its own files, and the
  // ILIAS fonts/images whose URL prefix the skin configures. Anything else (e.g. a
  // script missing from the ILIAS build) is reported but is not a skin defect.
  const isSkinAsset = (line) => /\/Customizing\/skin\/|\/assets\/(fonts|images)\//.test(line);
  const unique = [...new Set(failed)];
  const fatal = unique.filter(isSkinAsset);
  const other = unique.filter((line) => !isSkinAsset(line));
  if (other.length > 0) {
    console.warn('Not loaded (not part of the skin):');
    other.forEach((line) => console.warn(`  ${line}`));
  }
  if (fatal.length > 0) {
    console.error('Skin assets that failed to load:');
    fatal.forEach((line) => console.error(`  ${line}`));
    process.exitCode = 1;
  } else {
    console.log('All skin assets loaded.');
  }
}

main().catch((err) => {
  console.error(`shoot.js: ${err.message}`);
  process.exit(1);
});
