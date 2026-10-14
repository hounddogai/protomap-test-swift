import AcmePlatform
import Foundation

extension RevenueCycle {
    static func adaptiveRemittanceGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func mergeAdaptiveRemittanceGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive remittance group score falls in.
    static func classifyAdaptiveRemittanceGroup(_ score: Double) -> String {
        if score < 43.0 {
            return "medium"
        }
        if score < 48.5 {
            return "low"
        }
        if score < 94.8 {
            return "watch"
        }
        return "minimal"
    }

    static func adaptiveRemittanceGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
