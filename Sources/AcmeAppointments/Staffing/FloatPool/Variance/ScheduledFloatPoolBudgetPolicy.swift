import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 51358.0, in order.
    static func scheduledFloatPoolBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51358.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled float pool budget score falls in.
    static func classifyScheduledFloatPoolBudget(_ score: Double) -> String {
        if score < 41.2 {
            return "critical"
        }
        if score < 65.4 {
            return "watch"
        }
        return "low"
    }

    /// Puts a scheduled float pool budget code in its canonical SFPB- form.
    static func normalizeScheduledFloatPoolBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFPB-") {
            return clean
        }
        return "SFPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
