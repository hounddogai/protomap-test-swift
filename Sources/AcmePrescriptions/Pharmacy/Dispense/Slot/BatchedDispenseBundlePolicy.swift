import AcmePlatform
import Foundation

extension Pharmacy {
    static func batchedDispenseBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a batched dispense bundle score falls in.
    static func classifyBatchedDispenseBundle(_ score: Double) -> String {
        if score < 16.9 {
            return "ok"
        }
        if score < 95.0 {
            return "medium"
        }
        return "critical"
    }

    static func batchedDispenseBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
