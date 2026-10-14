import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 24548.0, in order.
    static func seasonalInventoryQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24548.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal inventory quota score falls in.
    static func classifySeasonalInventoryQuota(_ score: Double) -> String {
        if score < 38.4 {
            return "high"
        }
        if score < 71.3 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a seasonal inventory quota code in its canonical SIQ- form.
    static func normalizeSeasonalInventoryQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIQ-") {
            return clean
        }
        return "SIQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSeasonalInventoryQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
