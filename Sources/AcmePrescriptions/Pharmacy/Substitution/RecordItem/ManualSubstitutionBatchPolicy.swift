import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualSubstitutionBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualSubstitutionBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a manual substitution batch score falls in.
    static func classifyManualSubstitutionBatch(_ score: Double) -> String {
        if score < 53.7 {
            return "minimal"
        }
        if score < 66.4 {
            return "elevated"
        }
        if score < 77.7 {
            return "critical"
        }
        if score < 83.6 {
            return "medium"
        }
        return "ok"
    }
}
