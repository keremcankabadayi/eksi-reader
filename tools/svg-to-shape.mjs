import fs from 'node:fs'

// Kaynak: Ekşi'nin herhangi bir sayfasının HTML'i (sayfa başında `eksico-*`
// symbol'lerini taşıyan gizli SVG sprite'ı var).
//   curl -sL --compressed "https://web.archive.org/web/2026id_/https://eksisozluk.com/stalker--35789" -o eksi.html
//   node tools/svg-to-shape.mjs eksi.html Sources/Views/EksiIcons.swift
const [source, target] = process.argv.slice(2)
if (!source || !target) {
  console.error('kullanım: node tools/svg-to-shape.mjs <eksi-sayfası.html> <hedef.swift>')
  process.exit(1)
}
const html = fs.readFileSync(source, 'utf8')

function paths(id) {
  const m = html.match(new RegExp(`<symbol id="${id}"(.*?)</symbol>`, 's'))
  return [...m[1].matchAll(/ d="([^"]+)"/g)].map(x => x[1])
}


function tokenize(d) {
  const out = []
  const re = /([MmLlHhVvCcSsZz])|(-?\d*\.?\d+(?:e[-+]?\d+)?)/g
  let m
  while ((m = re.exec(d))) out.push(m[1] ?? parseFloat(m[2]))
  return out
}

function convert(d) {
  const t = tokenize(d)
  const lines = []
  let i = 0, cmd = null, x = 0, y = 0, sx = 0, sy = 0, prevC = null
  const P = (a, b) => `p(${+a.toFixed(5)}, ${+b.toFixed(5)})`
  while (i < t.length) {
    if (typeof t[i] === 'string') { cmd = t[i]; i++ }
    const rel = cmd === cmd.toLowerCase()
    const C = cmd.toUpperCase()
    if (C === 'Z') { lines.push(`path.closeSubpath()`); x = sx; y = sy; prevC = null; continue }
    const n = { M: 2, L: 2, H: 1, V: 1, C: 6, S: 4 }[C]
    const a = t.slice(i, i + n); i += n
    if (C === 'M') {
      x = rel ? x + a[0] : a[0]; y = rel ? y + a[1] : a[1]; sx = x; sy = y
      lines.push(`path.move(to: ${P(x, y)})`); cmd = rel ? 'l' : 'L'; prevC = null
    } else if (C === 'L') {
      x = rel ? x + a[0] : a[0]; y = rel ? y + a[1] : a[1]
      lines.push(`path.addLine(to: ${P(x, y)})`); prevC = null
    } else if (C === 'H') {
      x = rel ? x + a[0] : a[0]
      lines.push(`path.addLine(to: ${P(x, y)})`); prevC = null
    } else if (C === 'V') {
      y = rel ? y + a[0] : a[0]
      lines.push(`path.addLine(to: ${P(x, y)})`); prevC = null
    } else if (C === 'C' || C === 'S') {
      let c1x, c1y, c2x, c2y, ex, ey
      if (C === 'C') {
        ;[c1x, c1y, c2x, c2y, ex, ey] = rel ? [x + a[0], y + a[1], x + a[2], y + a[3], x + a[4], y + a[5]] : a
      } else {
        ;[c2x, c2y, ex, ey] = rel ? [x + a[0], y + a[1], x + a[2], y + a[3]] : a
        c1x = prevC ? 2 * x - prevC[0] : x
        c1y = prevC ? 2 * y - prevC[1] : y
      }
      lines.push(`path.addCurve(to: ${P(ex, ey)},\n                      control1: ${P(c1x, c1y)},\n                      control2: ${P(c2x, c2y)})`)
      prevC = [c2x, c2y]; x = ex; y = ey
    }
  }
  return lines
}

const icons = [
  { name: 'EksiFlame', id: 'eksico-drop-new', box: 16, doc: 'favori (şükela damlası) ikonu, dolu çizilir' },
  { name: 'EksiHeart', id: 'eksico-chevron-down', box: 16, doc: 'artı oy ikonu, boş kalp (dolu çizilen çerçeve)' },
  { name: 'EksiHeartFill', id: 'eksico-chevron-up', box: 16, doc: 'artı oy verilmiş hâli, dolu kalp' },
  { name: 'EksiDislike', id: 'eksico-dislike', box: 16, doc: 'eksi oy ikonu; çizgi (stroke) olarak çizilir' },
  { name: 'EksiDislikeFill', id: 'eksico-dislike-fill', box: 16, doc: 'eksi oy verilmiş hâli, dolu kutu' },
]

let out = `import SwiftUI

// Ekşi'nin kendi SVG sprite'ından (\`eksico-*\` symbol'leri) birebir alınan
// ikonlar. SF Symbol karşılıkları tutmuyor, yolları elle çiziyoruz.
// Bu dosya \`tools/svg-to-shape.mjs\` benzeri bir dönüşümle üretildi;
// düzeltmek gerekirse path verisini kaynaktan yeniden al.

/// 16x16 viewBox'ı hedef dikdörtgende oranı bozmadan ortalıyor.
private struct SVGCanvas {
    let dx: CGFloat
    let dy: CGFloat
    let scale: CGFloat

    init(_ rect: CGRect, box: CGFloat = 16) {
        let side = min(rect.width, rect.height)
        scale = side / box
        dx = rect.minX + (rect.width - side) / 2
        dy = rect.minY + (rect.height - side) / 2
    }

    func callAsFunction(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: dx + x * scale, y: dy + y * scale)
    }
}
`

for (const icon of icons) {
  const body = paths(icon.id).map(d => convert(d).map(l => '        ' + l).join('\n')).join('\n\n')
  out += `
/// Ekşi \`${icon.id}\`: ${icon.doc}.
struct ${icon.name}: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
${body}
        return path
    }
}
`
}

fs.writeFileSync(target, out)
console.log(out.split('\n').length, 'satır')
