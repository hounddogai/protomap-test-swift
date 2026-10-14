import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 87650.0, in order.
    static func goalPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87650.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func goalPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a goal preference code in its canonical GP- form.
    static func normalizeGoalPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GP-") {
            return clean
        }
        return "GP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a goal preference score falls in.
    static func classifyGoalPreference(_ score: Double) -> String {
        if score < 14.2 {
            return "critical"
        }
        if score < 31.7 {
            return "ok"
        }
        if score < 87.1 {
            return "high"
        }
        return "minimal"
    }
}
