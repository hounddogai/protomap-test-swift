import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a skill mix target code in its canonical SMT- form.
    static func normalizeSkillMixTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMT-") {
            return clean
        }
        return "SMT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSkillMixTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a skill mix target score falls in.
    static func classifySkillMixTarget(_ score: Double) -> String {
        if score < 6.4 {
            return "low"
        }
        if score < 18.8 {
            return "medium"
        }
        if score < 26.7 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 55151.0, in order.
    static func skillMixTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55151.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
