import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 54626.0, in order.
    static func goalDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54626.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func goalDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a goal draft score falls in.
    static func classifyGoalDraft(_ score: Double) -> String {
        if score < 24.4 {
            return "high"
        }
        if score < 66.6 {
            return "minimal"
        }
        if score < 83.5 {
            return "critical"
        }
        return "ok"
    }

    /// Puts a goal draft code in its canonical GD- form.
    static func normalizeGoalDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GD-") {
            return clean
        }
        return "GD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
