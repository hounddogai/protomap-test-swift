import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a assessment adjustment code in its canonical AA- form.
    static func normalizeAssessmentAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func assessmentAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a assessment adjustment score falls in.
    static func classifyAssessmentAdjustment(_ score: Double) -> String {
        if score < 19.6 {
            return "low"
        }
        if score < 52.3 {
            return "elevated"
        }
        if score < 73.1 {
            return "medium"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 24927.0, in order.
    static func assessmentAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24927.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
