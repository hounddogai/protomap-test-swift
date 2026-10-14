import AcmePlatform
import Foundation

extension Pharmacy {
    static func dispenseBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a dispense bundle score falls in.
    static func classifyDispenseBundle(_ score: Double) -> String {
        if score < 29.3 {
            return "medium"
        }
        if score < 83.6 {
            return "low"
        }
        return "watch"
    }

    static func dispenseBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
