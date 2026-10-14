import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap digest score falls in.
    static func classifyCareGapDigest(_ score: Double) -> String {
        if score < 11.1 {
            return "watch"
        }
        if score < 19.0 {
            return "minimal"
        }
        return "elevated"
    }

    static func careGapDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 98746.0, in order.
    static func careGapDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98746.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCareGapDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
