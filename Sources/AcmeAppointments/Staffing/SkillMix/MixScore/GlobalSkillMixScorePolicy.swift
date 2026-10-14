import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a global skill mix score code in its canonical GSMS- form.
    static func normalizeGlobalSkillMixScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSMS-") {
            return clean
        }
        return "GSMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global skill mix score score falls in.
    static func classifyGlobalSkillMixScore(_ score: Double) -> String {
        if score < 7.1 {
            return "critical"
        }
        if score < 9.7 {
            return "elevated"
        }
        if score < 68.2 {
            return "medium"
        }
        if score < 85.8 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 8796.0, in order.
    static func globalSkillMixScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8796.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalSkillMixScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
