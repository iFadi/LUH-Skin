#!/usr/bin/env node
/*
 * Regenerate the README login screenshot (screenshots/luh-skin-release_10-1.png).
 *
 * Why a script: the local ILIAS docker instance has no Shibboleth, so the real
 * "Login mit WebSSO" option is not rendered there. This script injects that option
 * exactly as ILIAS emits it on the production LUH server (see
 * components/ILIAS/Init/tpl.login_form_shibboleth.html), so the screenshot reflects
 * what users actually see rather than the WebSSO-less test instance.
 *
 * Usage:
 *   1. Bring up the ILIAS 10 stack (docker compose up -d in ../ilias10) and recompile
 *      the skin CSS (./update-skin.sh ...), so localhost:8081 serves the current skin.
 *   2. Run:  npx puppeteer@24 --yes node tools/shoot-login.js
 *      or, with puppeteer installed:  node tools/shoot-login.js
 *
 * Env overrides:
 *   LOGIN_URL   default http://localhost:8081/login.php
 *   OUT_PATH    default screenshots/luh-skin-release_10-1.png
 *   CHROME_PATH path to a Chrome/Chromium binary (else puppeteer's bundled browser)
 */
'use strict';

const path = require('path');
const puppeteer = require('puppeteer');

const URL = process.env.LOGIN_URL || 'http://localhost:8081/login.php';
const OUT =
  process.env.OUT_PATH ||
  path.join(__dirname, '..', 'screenshots', 'luh-skin-release_10-1.png');

// Matches the framing of the committed README screenshot (1300x760 @2x = 2600x1520).
const VIEWPORT = { width: 1300, height: 760, deviceScaleFactor: 2 };

(async () => {
  const launchOpts = {
    headless: 'new',
    args: ['--no-sandbox', '--force-color-profile=srgb', '--hide-scrollbars'],
  };
  if (process.env.CHROME_PATH) {
    launchOpts.executablePath = process.env.CHROME_PATH;
  }

  const browser = await puppeteer.launch(launchOpts);
  try {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await page.goto(URL, { waitUntil: 'networkidle0', timeout: 60000 });

    // Inject the WebSSO login option (as tpl.login_form_shibboleth.html renders it).
    await page.evaluate(() => {
      const mask = document.querySelector('#shib-form-login-mask');
      if (mask && !mask.querySelector('#shib_login')) {
        mask.innerHTML =
          '<div class="ilForm"><form class="form-horizontal">' +
          '<a id="shib_login" class="luh-login-action" href="#" aria-label="Login mit WebSSO">Login mit WebSSO</a>' +
          '<p class="luh-login-desc">für Angehörige der LUH</p>' +
          '</form></div>';
      }
    });

    await page.evaluate(() => document.fonts && document.fonts.ready);
    await new Promise((r) => setTimeout(r, 400));

    await page.screenshot({ path: OUT, fullPage: false });
    console.log('Saved screenshot ->', OUT);
  } finally {
    await browser.close();
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
