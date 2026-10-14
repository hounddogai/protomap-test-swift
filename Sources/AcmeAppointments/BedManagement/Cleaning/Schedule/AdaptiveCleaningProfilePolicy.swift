import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a adaptive cleaning profile score falls in.
    static func classifyAdaptiveCleaningProfile(_ score: Double) -> String {
        if score < 49.1 {
            return "watch"
        }
        if score < 66.1 {
            return "elevated"
        }
        if score < 95.8 {
            return "critical"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 56462.0, in order.
    static func adaptiveCleaningProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 56462.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive cleaning profile code in its canonical ACP- form.
    static func normalizeAdaptiveCleaningProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACP-") {
            return clean
        }
        return "ACP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
