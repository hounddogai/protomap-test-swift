import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a courier bundle score falls in.
    static func classifyCourierBundle(_ score: Double) -> String {
        if score < 53.4 {
            return "minimal"
        }
        if score < 92.4 {
            return "ok"
        }
        return "low"
    }

    static func courierBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func courierBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
