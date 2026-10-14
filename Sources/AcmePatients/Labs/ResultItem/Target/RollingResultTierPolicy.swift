import AcmePlatform
import Foundation

extension Labs {
    /// Puts a rolling result tier code in its canonical RRT- form.
    static func normalizeRollingResultTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRT-") {
            return clean
        }
        return "RRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling result tier score falls in.
    static func classifyRollingResultTier(_ score: Double) -> String {
        if score < 8.1 {
            return "high"
        }
        if score < 10.0 {
            return "critical"
        }
        if score < 41.5 {
            return "medium"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 58927.0, in order.
    static func rollingResultTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58927.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
