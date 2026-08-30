import SwiftUI

// Ekşi'nin kendi SVG sprite'ından (`eksico-*` symbol'leri) birebir alınan
// ikonlar. SF Symbol karşılıkları tutmuyor, yolları elle çiziyoruz.
// ÜRETİLMİŞ DOSYA: `node tools/svg-to-shape.mjs <eksi-sayfası.html> <hedef.swift>`.
// Elle düzenleme; ikon değişirse betiği taze HTML ile yeniden koştur.

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

/// Ekşi `eksico-drop-new`: favori (şükela damlası) ikonu, dolu çizilir.
struct EksiFlame: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
        path.move(to: p(8.00089, 15.5))
        path.addCurve(to: p(2.78906, 10.2802),
                      control1: p(5.11303, 15.5),
                      control2: p(2.78906, 13.1738))
        path.addCurve(to: p(3.63177, 7.58702),
                      control1: p(2.78906, 9.62859),
                      control2: p(3.10025, 8.68751))
        path.addCurve(to: p(5.56344, 4.25433),
                      control1: p(4.1541, 6.50557),
                      control2: p(4.85526, 5.33726))
        path.addCurve(to: p(7.51006, 1.46929),
                      control1: p(6.27048, 3.17316),
                      control2: p(6.97841, 2.18634))
        path.addCurve(to: p(8.00089, 0.81652),
                      control1: p(7.69875, 1.21481),
                      control2: p(7.86502, 0.99459))
        path.addCurve(to: p(8.49172, 1.46929),
                      control1: p(8.13677, 0.99459),
                      control2: p(8.30304, 1.21481))
        path.addCurve(to: p(10.4383, 4.25433),
                      control1: p(9.02337, 2.18634),
                      control2: p(9.73131, 3.17316))
        path.addCurve(to: p(12.37, 7.58702),
                      control1: p(11.1465, 5.33726),
                      control2: p(11.8477, 6.50557))
        path.addCurve(to: p(13.2127, 10.2802),
                      control1: p(12.9015, 8.68751),
                      control2: p(13.2127, 9.62859))
        path.addCurve(to: p(8.00089, 15.5),
                      control1: p(13.2127, 13.1738),
                      control2: p(10.8888, 15.5))
        path.closeSubpath()
        return path
    }
}

/// Ekşi `eksico-chevron-down`: artı oy ikonu, boş kalp (dolu çizilen çerçeve).
struct EksiHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
        path.move(to: p(7.625, 4.08126))
        path.addLine(to: p(7.25, 3.65938))
        path.addLine(to: p(7.11875, 3.51251))
        path.addCurve(to: p(3.875, 2.39376),
                      control1: p(6.30625, 2.60001),
                      control2: p(5.07812, 2.17501))
        path.addCurve(to: p(1, 5.84063),
                      control1: p(2.20937, 2.69688),
                      control2: p(1, 4.14688))
        path.addLine(to: p(1, 5.95001))
        path.addCurve(to: p(2.15937, 8.60938),
                      control1: p(1, 6.95938),
                      control2: p(1.41875, 7.92188))
        path.addLine(to: p(7.90625, 13.9625))
        path.addCurve(to: p(8, 14),
                      control1: p(7.93125, 13.9844),
                      control2: p(7.96562, 14))
        path.addCurve(to: p(8.09375, 13.9625),
                      control1: p(8.03438, 14),
                      control2: p(8.06875, 13.9875))
        path.addLine(to: p(13.8438, 8.60938))
        path.addCurve(to: p(15, 5.95001),
                      control1: p(14.5813, 7.92188),
                      control2: p(15, 6.95938))
        path.addLine(to: p(15, 5.84063))
        path.addCurve(to: p(12.125, 2.39376),
                      control1: p(15, 4.14688),
                      control2: p(13.7906, 2.69688))
        path.addCurve(to: p(8.88125, 3.51251),
                      control1: p(10.9219, 2.17501),
                      control2: p(9.69375, 2.60001))
        path.addLine(to: p(8.75, 3.65938))
        path.addLine(to: p(8.375, 4.08126))
        path.addCurve(to: p(8, 4.25001),
                      control1: p(8.28125, 4.18751),
                      control2: p(8.14375, 4.25001))
        path.addCurve(to: p(7.625, 4.08126),
                      control1: p(7.85625, 4.25001),
                      control2: p(7.72188, 4.18751))
        path.closeSubpath()
        path.move(to: p(8.71562, 2.29688))
        path.addCurve(to: p(12.3031, 1.40938),
                      control1: p(9.71875, 1.51251),
                      control2: p(11.0219, 1.17813))
        path.addCurve(to: p(16, 5.84063),
                      control1: p(14.4438, 1.80001),
                      control2: p(16, 3.66563))
        path.addLine(to: p(16, 5.95001))
        path.addCurve(to: p(14.8562, 8.99688),
                      control1: p(16, 7.07501),
                      control2: p(15.5906, 8.15626))
        path.addCurve(to: p(14.5219, 9.34063),
                      control1: p(14.75, 9.11563),
                      control2: p(14.6406, 9.23126))
        path.addLine(to: p(8.77188, 14.6938))
        path.addCurve(to: p(8.69063, 14.7625),
                      control1: p(8.74688, 14.7188),
                      control2: p(8.71875, 14.7406))
        path.addCurve(to: p(8, 14.9969),
                      control1: p(8.49375, 14.9156),
                      control2: p(8.25, 14.9969))
        path.addCurve(to: p(7.225, 14.6938),
                      control1: p(7.7125, 14.9969),
                      control2: p(7.4375, 14.8875))
        path.addLine(to: p(1.475, 9.34376))
        path.addCurve(to: p(1.14062, 9.00001),
                      control1: p(1.35625, 9.23438),
                      control2: p(1.24688, 9.11876))
        path.addCurve(to: p(0, 5.95001),
                      control1: p(0.40937, 8.15626),
                      control2: p(0, 7.07501))
        path.addLine(to: p(0, 5.84063))
        path.addCurve(to: p(3.69688, 1.40938),
                      control1: p(0, 3.66563),
                      control2: p(1.55625, 1.80001))
        path.addCurve(to: p(7.28125, 2.29688),
                      control1: p(4.975, 1.17813),
                      control2: p(6.27812, 1.50938))
        path.addCurve(to: p(7.86562, 2.84688),
                      control1: p(7.49062, 2.46251),
                      control2: p(7.6875, 2.64376))
        path.addLine(to: p(7.99687, 2.99376))
        path.addLine(to: p(8.12813, 2.84688))
        path.addCurve(to: p(8.54375, 2.43751),
                      control1: p(8.25938, 2.70001),
                      control2: p(8.39687, 2.56251))
        path.addCurve(to: p(8.7125, 2.29688),
                      control1: p(8.6, 2.39063),
                      control2: p(8.65625, 2.34376))
        path.addLine(to: p(8.71562, 2.29688))
        path.closeSubpath()
        return path
    }
}

/// Ekşi `eksico-chevron-up`: artı oy verilmiş hâli, dolu kalp.
struct EksiHeartFill: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
        path.move(to: p(1.4875, 9.3875))
        path.addLine(to: p(7.13438, 14.6594))
        path.addCurve(to: p(8, 15),
                      control1: p(7.36875, 14.8781),
                      control2: p(7.67812, 15))
        path.addCurve(to: p(8.86563, 14.6594),
                      control1: p(8.32187, 15),
                      control2: p(8.63125, 14.8781))
        path.addLine(to: p(14.5125, 9.3875))
        path.addCurve(to: p(16, 5.96562),
                      control1: p(15.4625, 8.50312),
                      control2: p(16, 7.2625))
        path.addLine(to: p(16, 5.78437))
        path.addCurve(to: p(12.2688, 1.37812),
                      control1: p(16, 3.6),
                      control2: p(14.4219, 1.7375))
        path.addCurve(to: p(8.375, 2.625),
                      control1: p(10.8438, 1.14062),
                      control2: p(9.39375, 1.60625))
        path.addLine(to: p(8, 3))
        path.addLine(to: p(7.625, 2.625))
        path.addCurve(to: p(3.73125, 1.37812),
                      control1: p(6.60625, 1.60625),
                      control2: p(5.15625, 1.14062))
        path.addCurve(to: p(0, 5.78437),
                      control1: p(1.57812, 1.7375),
                      control2: p(0, 3.6))
        path.addLine(to: p(0, 5.96562))
        path.addCurve(to: p(1.4875, 9.3875),
                      control1: p(0, 7.2625),
                      control2: p(0.5375, 8.50312))
        path.closeSubpath()
        return path
    }
}

/// Ekşi `eksico-dislike`: eksi oy ikonu; çizgi (stroke) olarak çizilir.
struct EksiDislike: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
        path.move(to: p(5.33594, 8))
        path.addLine(to: p(10.6693, 8))

        path.move(to: p(6.0026, 14.6667))
        path.addLine(to: p(10.0026, 14.6667))
        path.addCurve(to: p(14.6693, 10),
                      control1: p(13.3359, 14.6667),
                      control2: p(14.6693, 13.3333))
        path.addLine(to: p(14.6693, 6.00001))
        path.addCurve(to: p(10.0026, 1.33334),
                      control1: p(14.6693, 2.66668),
                      control2: p(13.3359, 1.33334))
        path.addLine(to: p(6.0026, 1.33334))
        path.addCurve(to: p(1.33594, 6.00001),
                      control1: p(2.66927, 1.33334),
                      control2: p(1.33594, 2.66668))
        path.addLine(to: p(1.33594, 10))
        path.addCurve(to: p(6.0026, 14.6667),
                      control1: p(1.33594, 13.3333),
                      control2: p(2.66927, 14.6667))
        path.closeSubpath()
        return path
    }
}

/// Ekşi `eksico-dislike-fill`: eksi oy verilmiş hâli, dolu kutu.
struct EksiDislikeFill: Shape {
    func path(in rect: CGRect) -> Path {
        let p = SVGCanvas(rect)
        var path = Path()
        path.move(to: p(10.7959, 1.33334))
        path.addLine(to: p(5.20927, 1.33334))
        path.addCurve(to: p(1.33594, 5.20668),
                      control1: p(2.7826, 1.33334),
                      control2: p(1.33594, 2.78001))
        path.addLine(to: p(1.33594, 10.7867))
        path.addCurve(to: p(5.20927, 14.6667),
                      control1: p(1.33594, 13.22),
                      control2: p(2.7826, 14.6667))
        path.addLine(to: p(10.7893, 14.6667))
        path.addCurve(to: p(14.6626, 10.7933),
                      control1: p(13.2159, 14.6667),
                      control2: p(14.6626, 13.22))
        path.addLine(to: p(14.6626, 5.20668))
        path.addCurve(to: p(10.7959, 1.33334),
                      control1: p(14.6693, 2.78001),
                      control2: p(13.2226, 1.33334))
        path.closeSubpath()
        path.move(to: p(10.6693, 8.50001))
        path.addLine(to: p(5.33594, 8.50001))
        path.addCurve(to: p(4.83594, 8.00001),
                      control1: p(5.0626, 8.50001),
                      control2: p(4.83594, 8.27334))
        path.addCurve(to: p(5.33594, 7.50001),
                      control1: p(4.83594, 7.72668),
                      control2: p(5.0626, 7.50001))
        path.addLine(to: p(10.6693, 7.50001))
        path.addCurve(to: p(11.1693, 8.00001),
                      control1: p(10.9426, 7.50001),
                      control2: p(11.1693, 7.72668))
        path.addCurve(to: p(10.6693, 8.50001),
                      control1: p(11.1693, 8.27334),
                      control2: p(10.9426, 8.50001))
        path.closeSubpath()
        return path
    }
}
