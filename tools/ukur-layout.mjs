// Ukur layout nyata di beberapa lebar layar lewat CDP.
// Dipakai sekali untuk memastikan tidak ada overflow horizontal.
import { spawn } from 'node:child_process'
import { mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import WebSocket from 'ws'

const EDGE = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
const URL = process.argv[2] ?? 'http://localhost:3000/'
const LEBAR = (process.env.LEBAR ?? '320,360,480,700,768,900,1024,1440,1920').split(',').map(Number)

const UKUR_DEFAULT = `(() => {
  const vw = document.documentElement.clientWidth
  const doc = document.documentElement
  const nav = [...document.querySelectorAll('.bottom-nav-item')]
  const tight = nav.filter(el => el.scrollWidth > el.clientWidth + 1)
    .map(el => el.textContent.trim() + ' w=' + Math.round(el.getBoundingClientRect().width)
      + ' butuh=' + el.scrollWidth)
  // 64px adalah tinggi yang dirancang, jadi yang mencurigakan adalah lebih
  // dari itu: berarti label membungkus ke dua baris.
  const wrap = nav.filter(el => el.getBoundingClientRect().height > 66)
    .map(el => el.textContent.trim() + ' h=' + Math.round(el.getBoundingClientRect().height))
  return JSON.stringify({
    vw,
    scrollW: doc.scrollWidth,
    overflow: doc.scrollWidth > vw,
    sidebar: !!document.querySelector('.sidebar'),
    bottomNav: !!document.querySelector('.bottom-nav'),
    mainW: Math.round(document.querySelector('.app-main')?.getBoundingClientRect().width ?? 0),
    navJumlah: nav.length,
    navTerpotong: tight,
    navTinggi: wrap,
  })
})()`

const ukur = process.env.UKUR ?? UKUR_DEFAULT

//Dipakai untuk memeriksa tampilan yang butuh sesi: set role di state Nuxt
//lewat payload, tanpa menyentuh kode sumber.
const PURUS = process.env.PURUS

const profil = mkdtempSync(join(tmpdir(), 'cdp-'))
const port = 9222 + Math.floor(Math.random() * 500)
const edge = spawn(EDGE, [
  '--headless=new', '--no-sandbox', '--disable-gpu',
  `--user-data-dir=${profil}`, `--remote-debugging-port=${port}`, 'about:blank',
], { stdio: 'ignore' })

const tidur = ms => new Promise(r => setTimeout(r, ms))

async function target() {
  for (let i = 0; i < 40; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${port}/json/list`)
      const list = await r.json()
      const page = list.find(t => t.type === 'page')
      if (page) return page.webSocketDebuggerUrl
    } catch {}
    await tidur(300)
  }
  throw new Error('CDP tidak merespons')
}

const wsUrl = await target()
const ws = new WebSocket(wsUrl, { maxPayload: 64 * 1024 * 1024 })
await new Promise(r => ws.once('open', r))

let id = 0
const tunggu = new Map()
ws.on('message', d => {
  const m = JSON.parse(d)
  if (m.id && tunggu.has(m.id)) { tunggu.get(m.id)(m); tunggu.delete(m.id) }
})
function kirim(method, params = {}) {
  const i = ++id
  return new Promise(res => { tunggu.set(i, res); ws.send(JSON.stringify({ id: i, method, params })) })
}

await kirim('Page.enable')
await kirim('Runtime.enable')

console.log('lebar  scrollW  overflow  sidebar  bottomNav  appMain  yang melewati kanan')
for (const w of LEBAR) {
  await kirim('Emulation.setDeviceMetricsOverride', {
    width: w, height: 800, deviceScaleFactor: 1, mobile: w < 900,
  })
  await kirim('Page.navigate', { url: URL })
  await tidur(2200)
  if (PURUS) {
    await kirim('Runtime.evaluate', {
      expression: `(() => {
        const nuxt = window.__NUXT__
        if (!nuxt || !nuxt.state) return 'tidak ada __NUXT__.state'
        nuxt.state.role = '${PURUS}'
        return 'role=' + String(nuxt.state.role)
      })()`,
      returnByValue: true,
    })
    await tidur(800)
  }
  const r = await kirim('Runtime.evaluate', { expression: ukur, returnByValue: true })
  if (r.result?.exceptionDetails) {
    console.log('  EXCEPTION:', JSON.stringify(r.result.exceptionDetails).slice(0, 300))
    continue
  }
  const d = JSON.parse(r.result.result.value)
  const tanda = d.overflow ? 'YA' : 'tidak'
  console.log(
    String(d.vw).padEnd(6),
    String(d.scrollW).padEnd(8),
    tanda.padEnd(9),
    String(d.sidebar).padEnd(8),
    String(d.bottomNav).padEnd(10),
    String(d.mainW).padEnd(8),
    'nav=' + d.navJumlah,
  )
  if (d.navTerpotong?.length) console.log('        nav terpotong: ' + d.navTerpotong.join(' ; '))
  if (d.navTinggi?.length) console.log('        nav membungkus: ' + d.navTinggi.join(' ; '))
}

ws.close()
edge.kill()
