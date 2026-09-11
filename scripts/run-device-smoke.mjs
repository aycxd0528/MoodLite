#!/usr/bin/env node

import { existsSync, mkdtempSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, isAbsolute, join } from 'node:path';
import { spawnSync } from 'node:child_process';

const BUNDLE_NAME = 'com.aycxd.moodlite';
const TEST_MODULE = 'entry_test';
const TEST_SUITE = 'LaunchRouteSafety';

function defaultSignToolPath() {
  const sdkRoots = process.env.DEVECO_SDK_HOME
    ? [process.env.DEVECO_SDK_HOME, join(process.env.DEVECO_SDK_HOME, 'default')]
    : [];
  sdkRoots.push('/Applications/DevEco-Studio.app/Contents/sdk/default');
  const candidates = sdkRoots.map(root =>
    join(root, 'openharmony', 'toolchains', 'lib', 'hap-sign-tool.jar'));
  return candidates.find(candidate => existsSync(candidate)) ?? candidates[0];
}

function fail(message) {
  throw new Error(message);
}

function parseArgs(argv) {
  const options = {
    hdc: 'hdc',
    java: 'java',
    signTool: defaultSignToolPath(),
  };

  for (let index = 0; index < argv.length; index += 2) {
    const name = argv[index];
    const value = argv[index + 1];
    if (!name?.startsWith('--') || value === undefined) {
      fail(`invalid arguments near ${name ?? '<end>'}`);
    }
    switch (name) {
      case '--app-hap':
        options.appHap = value;
        break;
      case '--test-hap':
        options.testHap = value;
        break;
      case '--target':
        options.target = value;
        break;
      case '--hdc':
        options.hdc = value;
        break;
      case '--java':
        options.java = value;
        break;
      case '--sign-tool':
        options.signTool = value;
        break;
      case '--flight-mode-confirmed':
        options.flightModeConfirmed = value;
        break;
      default:
        fail(`unknown option ${name}`);
    }
  }
  return options;
}

function requireFile(path, label) {
  if (!path) {
    fail(`${label} is required`);
  }
  if (!isAbsolute(path)) {
    fail(`${label} must be an absolute path`);
  }
  if (!existsSync(path) || !statSync(path).isFile()) {
    fail(`${label} does not exist: ${path}`);
  }
}

function run(command, args) {
  const result = spawnSync(command, args, { encoding: 'utf8' });
  if (result.error) {
    fail(`could not run ${basename(command)}: ${result.error.message}`);
  }
  return result;
}

function verifySignedHap(java, signTool, hap, outputDirectory, suffix) {
  const result = run(java, [
    '-jar', signTool,
    'verify-app',
    '-inFile', hap,
    '-outCertChain', join(outputDirectory, `${suffix}-cert-chain.cer`),
    '-outProfile', join(outputDirectory, `${suffix}-profile.p7b`),
  ]);
  if (result.status !== 0) {
    fail(`signature verification failed for ${basename(hap)}`);
  }
}

function connectedTargets(hdc) {
  const result = run(hdc, ['list', 'targets']);
  if (result.status !== 0) {
    fail(`hdc list targets exited with ${result.status}`);
  }
  return result.stdout
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(line => line && line !== '[Empty]')
    .map(line => line.split(/\s+/)[0]);
}

function selectTarget(targets, requested) {
  if (targets.length === 0) {
    fail('no connected HarmonyOS device');
  }
  if (requested) {
    if (!targets.includes(requested)) {
      fail(`requested device is not connected: ${requested}`);
    }
    return requested;
  }
  if (targets.length > 1) {
    fail('multiple devices are connected; pass --target explicitly');
  }
  return targets[0];
}

function printCommandOutput(result) {
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
}

try {
  const options = parseArgs(process.argv.slice(2));
  requireFile(options.appHap, '--app-hap');
  requireFile(options.testHap, '--test-hap');
  requireFile(options.signTool, '--sign-tool');
  if (options.flightModeConfirmed !== 'yes') {
    fail('flight mode must be confirmed with --flight-mode-confirmed yes');
  }

  for (const hap of [options.appHap, options.testHap]) {
    if (/unsigned\.hap$/i.test(basename(hap))) {
      fail(`refusing obvious unsigned HAP: ${hap}`);
    }
  }

  const verificationDirectory = mkdtempSync(join(tmpdir(), 'moodlite-hap-verify-'));
  try {
    verifySignedHap(options.java, options.signTool, options.appHap, verificationDirectory, 'app');
    verifySignedHap(options.java, options.signTool, options.testHap, verificationDirectory, 'test');

    const target = selectTarget(connectedTargets(options.hdc), options.target);
    console.log(`Target: ${target}`);
    console.log('Flight-mode confirmation received.');

    const install = run(options.hdc, [
      '-t', target,
      'install', '-r',
      options.appHap,
      options.testHap,
    ]);
    printCommandOutput(install);
    if (install.status !== 0) {
      fail(`HAP installation exited with ${install.status}`);
    }

    const testResult = run(options.hdc, [
      '-t', target,
      'shell', 'aa', 'test',
      '-b', BUNDLE_NAME,
      '-m', TEST_MODULE,
      '-s', 'unittest', 'OpenHarmonyTestRunner',
      '-s', 'class', TEST_SUITE,
    ]);
    printCommandOutput(testResult);
    if (testResult.status !== 0) {
      fail(`aa test exited with ${testResult.status}`);
    }

    const report = `${testResult.stdout}\n${testResult.stderr}`;
    const summary = report.match(/OHOS_REPORT_RESULT:\s*stream=Tests run:\s*(\d+),\s*Failure:\s*(\d+),\s*Error:\s*(\d+),\s*Pass:\s*(\d+)/);
    const successfulCode = /OHOS_REPORT_CODE:\s*0(?:\s|$)/.test(report);
    const successfulSummary = summary
      && Number(summary[1]) > 0
      && Number(summary[2]) === 0
      && Number(summary[3]) === 0
      && Number(summary[4]) > 0;
    if (!successfulCode || !successfulSummary) {
      fail('Hypium did not report success for the route-safety suite');
    }

    console.log(`Device smoke test passed: ${TEST_SUITE}`);
  } finally {
    rmSync(verificationDirectory, { recursive: true, force: true });
  }
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`device smoke test failed: ${message}`);
  process.exitCode = 1;
}
