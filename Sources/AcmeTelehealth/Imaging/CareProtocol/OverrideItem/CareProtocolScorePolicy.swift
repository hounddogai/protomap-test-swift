import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeCareProtocolScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 99121.0, in order.
    static func careProtocolScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99121.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care protocol score score falls in.
    static func classifyCareProtocolScore(_ score: Double) -> String {
        if score < 22.7 {
            return "minimal"
        }
        if score < 79.6 {
            return "elevated"
        }
        if score < 95.4 {
            return "high"
        }
        return "watch"
    }
}
