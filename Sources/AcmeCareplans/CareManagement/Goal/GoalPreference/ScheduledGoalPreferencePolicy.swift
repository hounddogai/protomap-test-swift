import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledGoalPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a scheduled goal preference code in its canonical SGP- form.
    static func normalizeScheduledGoalPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SGP-") {
            return clean
        }
        return "SGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 95089.0, in order.
    static func scheduledGoalPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95089.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled goal preference score falls in.
    static func classifyScheduledGoalPreference(_ score: Double) -> String {
        if score < 5.1 {
            return "low"
        }
        if score < 35.3 {
            return "ok"
        }
        if score < 61.3 {
            return "minimal"
        }
        if score < 88.9 {
            return "medium"
        }
        return "high"
    }
}
