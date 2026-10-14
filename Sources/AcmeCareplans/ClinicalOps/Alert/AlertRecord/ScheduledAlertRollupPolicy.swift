import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a scheduled alert rollup code in its canonical SAR- form.
    static func normalizeScheduledAlertRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAR-") {
            return clean
        }
        return "SAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 95748.0, in order.
    static func scheduledAlertRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95748.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledAlertRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled alert rollup score falls in.
    static func classifyScheduledAlertRollup(_ score: Double) -> String {
        if score < 39.2 {
            return "watch"
        }
        if score < 58.0 {
            return "medium"
        }
        return "elevated"
    }
}
