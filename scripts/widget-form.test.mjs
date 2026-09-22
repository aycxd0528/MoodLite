import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

// Exercise the real FormExtensionAbility and view models; only OS services are
// replaced. DevEco's bundled compiler avoids adding a product dependency.
const require = createRequire(import.meta.url);
const studio = process.env.DEVECO_STUDIO_HOME || '/Applications/DevEco-Studio.app/Contents';
const ts = require(resolve(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function createFormFixture(initialSnapshot = null) {
  const updates = [];
  const formIds = new Set();
  let storedSnapshot = initialSnapshot === null ? null : JSON.stringify(initialSnapshot);
  function snapshotResultSet() {
    return {
      goToFirstRow: () => storedSnapshot !== null,
      getColumnIndex: (column) => {
        assert.equal(column, 'payload');
        return 0;
      },
      getString: (columnIndex) => {
        assert.equal(columnIndex, 0);
        return storedSnapshot;
      },
      close: () => {},
    };
  }
  function formResultSet() {
    const ids = [...formIds];
    let index = -1;
    return {
      goToFirstRow: () => {
        index = ids.length > 0 ? 0 : -1;
        return index === 0;
      },
      goToNextRow: () => {
        index += 1;
        return index < ids.length;
      },
      getColumnIndex: (column) => {
        assert.equal(column, 'form_id');
        return 0;
      },
      getString: (columnIndex) => {
        assert.equal(columnIndex, 0);
        return ids[index];
      },
      close: () => {},
    };
  }
  const rdbStore = {
    executeSql: async (sql, args = []) => {
      if (/DELETE FROM widget_forms/.test(sql)) {
        formIds.delete(args[0]);
      }
    },
    insert: async (table, values, conflict) => {
      assert.equal(conflict, 5);
      if (table === 'widget_snapshot') {
        assert.equal(values.id, 1);
        storedSnapshot = values.payload;
      } else {
        assert.equal(table, 'widget_forms');
        formIds.add(values.form_id);
      }
      return 1;
    },
    querySql: async (sql, args) => {
      if (/SELECT payload FROM widget_snapshot/.test(sql)) {
        assert.equal(args.length, 1);
        assert.equal(args[0], 1);
        return snapshotResultSet();
      }
      assert.match(sql, /SELECT form_id FROM widget_forms/);
      return formResultSet();
    },
  };
  const services = {
    '@ohos.app.form.FormExtensionAbility': class {
      context = { filesDir: '/test/app/files' };
    },
    '@ohos.app.form.formInfo': {
      FormParam: { IDENTITY_KEY: 'ohos.extra.param.key.form_identity' },
    },
    '@ohos.app.form.formBindingData': { createFormBindingData: (data) => ({ data }) },
    '@ohos.app.form.formProvider': {
      updateForm: async (id, binding) => { updates.push({ id, data: binding.data }); },
    },
    '@ohos.data.relationalStore': {
      SecurityLevel: { S1: 1 },
      ConflictResolution: { ON_CONFLICT_REPLACE: 5 },
      getRdbStore: async (_context, config) => {
        assert.equal(config.name, 'moodlite_widget.db');
        assert.equal(config.securityLevel, 1);
        return rdbStore;
      },
    },
    '@ohos.data.preferences': {
      getPreferences: async () => {
        throw new Error('Form synchronization must not use Preferences across processes');
      },
    },
  };
  const cache = new Map();
  function load(path) {
    if (cache.has(path)) return cache.get(path).exports;
    const module = { exports: {} };
    cache.set(path, module);
    const compiled = ts.transpileModule(readFileSync(path, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
    }).outputText;
    runInNewContext(compiled, {
      module,
      exports: module.exports,
      console,
      AppStorage: { get: () => false },
      require: (specifier) => {
        if (specifier in services) return { default: services[specifier] };
        if (!specifier.startsWith('.')) throw new Error(`Unexpected dependency: ${specifier}`);
        return load(resolve(dirname(path), specifier + '.ets'));
      },
    }, { filename: path });
    return module.exports;
  }
  const { default: EntryFormAbility } = load(resolve(root, 'entry/src/main/ets/entryformability/EntryFormAbility.ets'));
  const { default: widgetSync } = load(resolve(root, 'entry/src/main/ets/common/utils/WidgetSyncManager.ets'));
  return {
    ability: new EntryFormAbility(),
    widgetSync,
    updates,
    formIds,
    getStoredSnapshot: () => storedSnapshot === null ? null : JSON.parse(storedSnapshot),
  };
}

function createDataManagerFixture() {
  let releaseSnapshot;
  const snapshotStarted = new Promise((resolveStarted) => {
    releaseSnapshot = { resolveStarted };
  });
  let finishSnapshot;
  const snapshotFinished = new Promise((resolveFinished) => {
    finishSnapshot = resolveFinished;
  });
  const preferences = {
    get: async (key) => {
      if (key === 'records') return '[]';
      return true;
    },
  };
  const cache = new Map();
  function load(path) {
    if (cache.has(path)) return cache.get(path).exports;
    const source = readFileSync(path, 'utf8');
    const output = ts.transpileModule(source, {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2020,
      },
    }).outputText;
    const module = { exports: {} };
    cache.set(path, module);
    const context = {
      module,
      exports: module.exports,
      console,
      require: (specifier) => {
        if (specifier === '@ohos.data.preferences') {
          return { default: { getPreferences: async () => preferences } };
        }
        if (specifier.endsWith('/WidgetSyncManager')) {
          return {
            default: {
              updateWidgets: async () => {
                releaseSnapshot.resolveStarted();
                await snapshotFinished;
              },
            },
          };
        }
        if (!specifier.startsWith('.')) throw new Error(`Unexpected dependency: ${specifier}`);
        return load(resolve(dirname(path), specifier + '.ets'));
      },
    };
    runInNewContext(`(function(require,module,exports){${output}\n})`, context)(context.require, module, module.exports);
    return module.exports;
  }
  const { default: dataManager } = load(resolve(root, 'entry/src/main/ets/data/DataManager.ets'));
  return { dataManager, snapshotStarted, finishSnapshot };
}

test('adding a card publishes the latest cross-process snapshot to the system ID', async () => {
  const fixture = createFormFixture({
    monthDays: [0, 0, 0], recordDays: 1, happyPercent: 100, sadPercent: 0,
    moodLabel: '愉悦', streak: 1, todayScore: 2, darkMode: 0,
  });
  fixture.ability.onAddForm({ parameters: { 'ohos.extra.param.key.form_identity': '577973689' } });
  await new Promise(setImmediate);
  assert.deepEqual([...fixture.formIds], ['577973689']);
  assert.equal(fixture.updates.length, 1);
  assert.equal(fixture.updates[0].id, '577973689');
  assert.equal(fixture.updates[0].data.moodLabel, '愉悦');
  assert.equal(fixture.updates[0].data.todayScore, 2);
  assert.equal(fixture.updates[0].data.recordDays, 1);
});

test('saving a second mood writes a shared snapshot and immediately updates registered forms', async () => {
  const now = new Date();
  const dateStr = [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');
  const fixture = createFormFixture();
  const context = { filesDir: '/test/app/files' };
  fixture.ability.onAddForm({ parameters: { 'ohos.extra.param.key.form_identity': '577973689' } });
  await new Promise(setImmediate);
  fixture.updates.splice(0);

  await fixture.widgetSync.updateWidgets(context, [
    {
      id: 'neutral', timestamp: now.getTime() - 120000, dateStr, score: 0,
      text: 'first', images: [], location: '', tags: [],
    },
    {
      id: 'happy', timestamp: now.getTime(), dateStr, score: 2,
      text: 'second', images: [], location: '', tags: [],
    },
  ]);

  const snapshot = fixture.getStoredSnapshot();
  assert.equal(snapshot.moodLabel, '愉悦');
  assert.equal(snapshot.todayScore, 2);
  assert.equal(fixture.updates.length, 1);
  assert.equal(fixture.updates[0].id, '577973689');
  assert.equal(fixture.updates[0].data.moodLabel, '愉悦');
  assert.equal(fixture.updates[0].data.todayScore, 2);
});

test('initialization waits for the initial widget snapshot before accepting writes', async () => {
  const fixture = createDataManagerFixture();
  let initialized = false;
  const initPromise = fixture.dataManager.init({ filesDir: '/test/app/files' }).then(() => {
    initialized = true;
  });

  await fixture.snapshotStarted;
  await new Promise(setImmediate);
  assert.equal(initialized, false);

  fixture.finishSnapshot();
  await initPromise;
  assert.equal(initialized, true);
});
