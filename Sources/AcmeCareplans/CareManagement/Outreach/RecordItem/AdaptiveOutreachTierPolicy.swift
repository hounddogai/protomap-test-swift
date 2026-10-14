import AcmePlatform
import Foundation

extension CareManagement {
    static func adaptiveOutreachTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveOutreachTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a adaptive outreach tier score falls in.
    static func classifyAdaptiveOutreachTier(_ score: Double) -> String {
        if score < 8.2 {
            return "elevated"
        }
        if score < 24.9 {
            return "ok"
        }
        if score < 68.6 {
            return "watch"
        }
        return "high"
    }
}
