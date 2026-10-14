import AcmePlatform
import Foundation

extension Staffing {
    static func strictShiftBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a strict shift bundle score falls in.
    static func classifyStrictShiftBundle(_ score: Double) -> String {
        if score < 24.7 {
            return "high"
        }
        if score < 64.7 {
            return "minimal"
        }
        return "critical"
    }

    static func strictShiftBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictShiftBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
