import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 23814.0, in order.
    static func seasonalReferenceRangeProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23814.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal reference range profile code in its canonical SRRP- form.
    static func normalizeSeasonalReferenceRangeProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRRP-") {
            return clean
        }
        return "SRRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSeasonalReferenceRangeProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a seasonal reference range profile score falls in.
    static func classifySeasonalReferenceRangeProfile(_ score: Double) -> String {
        if score < 35.9 {
            return "high"
        }
        if score < 93.3 {
            return "minimal"
        }
        return "critical"
    }
}
