// The page backdrop: the games' Neon Horizon (stars, striped sun, wire-mesh
// ridge, grid) on one fixed canvas behind everything. The grid scrolls and
// brightens on a heartbeat; the mouse nudges the mountains. With
// prefers-reduced-motion it draws one still frame and stops.
import { createHorizon } from './neonHorizon.js'

const canvas = document.getElementById('horizon')
const ctx = canvas && canvas.getContext('2d')
if (ctx) {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)')
  // The hero text sits left, so the sun sets on the right (as on Player One).
  // Phones keep it centred, low behind the grid; portrait tablets set it lower
  // and further right so it stays clear of the text. Rebuilt when the layout class changes.
  const layout = () => innerWidth < 600 ? 'phone' : innerHeight > innerWidth ? 'tall' : 'wide'
  const sunFor = { phone: { sunX: 0.5 }, tall: { sunX: 0.8, sunY: -1.2 }, wide: { sunX: 0.8 } }
  let mode = layout()
  let horizon = createHorizon({ ctx, sunJitter: false, ...sunFor[mode] })
  const BEAT = 0.92 // seconds between heartbeats
  let W = 0, H = 0, last = 0, sinceBeat = 0, raf = 0

  function size (force) {
    const w = innerWidth, h = innerHeight
    // Phones change height when the URL bar slides; ignore small height-only changes
    // so the stars do not reshuffle mid-scroll.
    if (!force && w === W && Math.abs(h - H) < 160) return
    W = w; H = h
    if (layout() !== mode) {
      mode = layout()
      horizon = createHorizon({ ctx, sunJitter: false, ...sunFor[mode] })
    }
    const dpr = Math.min(devicePixelRatio || 1, 2)
    canvas.width = Math.round(W * dpr)
    canvas.height = Math.round(H * dpr)
    canvas.style.height = H + 'px'
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    horizon.resize(W, H, ctx)
    if (reduce.matches) horizon.draw(ctx, 0)
  }

  function frame (now) {
    const t = now / 1000
    const dt = last ? Math.min(t - last, 0.1) : 0
    last = t
    sinceBeat += dt
    if (sinceBeat >= BEAT) { sinceBeat -= BEAT; horizon.beat() }
    horizon.update(dt)
    horizon.draw(ctx, t)
    raf = requestAnimationFrame(frame)
  }

  function start () {
    cancelAnimationFrame(raf)
    last = 0
    if (reduce.matches) horizon.draw(ctx, 0)
    else raf = requestAnimationFrame(frame)
  }

  size(true)
  start()
  addEventListener('resize', () => size(false))
  reduce.addEventListener('change', start)
  addEventListener('pointermove', e => {
    if (e.pointerType === 'mouse') horizon.setView(e.clientX / W * 2 - 1, (e.clientY / H * 2 - 1) * 0.4)
  }, { passive: true })
}
