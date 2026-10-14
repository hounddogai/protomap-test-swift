import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer preference score falls in.
    static func classifyTransferPreference(_ score: Double) -> String {
        if score < 9.5 {
            return "ok"
        }
        if score < 18.1 {
            return "minimal"
        }
        if score < 19.1 {
            return "high"
        }
        return "low"
    }

    static func mergeTransferPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 70136.0, in order.
    static func transferPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70136.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func transferPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
