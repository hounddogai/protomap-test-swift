import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 14943.0, in order.
    static func courierVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14943.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCourierVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a courier variance score falls in.
    static func classifyCourierVariance(_ score: Double) -> String {
        if score < 16.1 {
            return "elevated"
        }
        if score < 60.9 {
            return "minimal"
        }
        if score < 70.2 {
            return "watch"
        }
        return "medium"
    }
}
