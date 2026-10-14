import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a primary skill mix score code in its canonical PSMS- form.
    static func normalizePrimarySkillMixScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSMS-") {
            return clean
        }
        return "PSMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary skill mix score score falls in.
    static func classifyPrimarySkillMixScore(_ score: Double) -> String {
        if score < 14.9 {
            return "elevated"
        }
        if score < 55.3 {
            return "watch"
        }
        if score < 88.1 {
            return "medium"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 87413.0, in order.
    static func primarySkillMixScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87413.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
