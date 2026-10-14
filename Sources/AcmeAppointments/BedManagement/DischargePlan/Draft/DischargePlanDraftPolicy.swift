import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan draft code in its canonical DPD- form.
    static func normalizeDischargePlanDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPD-") {
            return clean
        }
        return "DPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 53704.0, in order.
    static func dischargePlanDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53704.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeDischargePlanDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a discharge plan draft score falls in.
    static func classifyDischargePlanDraft(_ score: Double) -> String {
        if score < 2.9 {
            return "critical"
        }
        if score < 23.1 {
            return "minimal"
        }
        if score < 72.6 {
            return "high"
        }
        return "medium"
    }
}
