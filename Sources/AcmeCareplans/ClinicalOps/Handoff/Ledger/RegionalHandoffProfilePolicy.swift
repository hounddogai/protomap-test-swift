import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 36527.0, in order.
    static func regionalHandoffProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36527.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a regional handoff profile code in its canonical RHP- form.
    static func normalizeRegionalHandoffProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RHP-") {
            return clean
        }
        return "RHP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalHandoffProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional handoff profile score falls in.
    static func classifyRegionalHandoffProfile(_ score: Double) -> String {
        if score < 29.8 {
            return "minimal"
        }
        if score < 49.2 {
            return "medium"
        }
        if score < 76.2 {
            return "critical"
        }
        return "elevated"
    }
}
