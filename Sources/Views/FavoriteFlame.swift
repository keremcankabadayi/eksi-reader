import SwiftUI

/// Ekşi'nin favori (şükela alevi) ikonu, 16x16 viewBox'lı SVG path'inin
/// birebir Swift karşılığı. SF Symbol'de karşılığı yok, elle çiziyoruz.
struct FavoriteFlame: Shape {
    func path(in rect: CGRect) -> Path {
        // Kare kutuda ortala; oran bozulmasın.
        let side = min(rect.width, rect.height)
        let scale = side / 16
        let dx = rect.minX + (rect.width - side) / 2
        let dy = rect.minY + (rect.height - side) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: dx + x * scale, y: dy + y * scale)
        }

        var path = Path()
        path.move(to: p(8.00089, 15.5))
        path.addCurve(to: p(2.78906, 10.2802),
                      control1: p(5.11303, 15.5), control2: p(2.78906, 13.1738))
        path.addCurve(to: p(3.63177, 7.58702),
                      control1: p(2.78906, 9.62859), control2: p(3.10025, 8.68751))
        path.addCurve(to: p(5.56344, 4.25433),
                      control1: p(4.1541, 6.50557), control2: p(4.85526, 5.33726))
        path.addCurve(to: p(7.51006, 1.46929),
                      control1: p(6.27048, 3.17316), control2: p(6.97841, 2.18634))
        path.addCurve(to: p(8.00089, 0.816519),
                      control1: p(7.69875, 1.21481), control2: p(7.86502, 0.994591))
        path.addCurve(to: p(8.49172, 1.46929),
                      control1: p(8.13677, 0.994591), control2: p(8.30304, 1.21481))
        path.addCurve(to: p(10.4383, 4.25433),
                      control1: p(9.02337, 2.18634), control2: p(9.73131, 3.17316))
        path.addCurve(to: p(12.37, 7.58702),
                      control1: p(11.1465, 5.33726), control2: p(11.8477, 6.50557))
        path.addCurve(to: p(13.2127, 10.2802),
                      control1: p(12.9015, 8.68751), control2: p(13.2127, 9.62859))
        path.addCurve(to: p(8.00089, 15.5),
                      control1: p(13.2127, 13.1738), control2: p(10.8888, 15.5))
        path.closeSubpath()
        return path
    }
}
