import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a scheduled reference range baseline score falls in.
    static func classifyScheduledReferenceRangeBaseline(_ score: Double) -> String {
        if score < 14.1 {
            return "watch"
        }
        if score < 31.5 {
            return "elevated"
        }
        if score < 57.5 {
            return "critical"
        }
        if score < 78.2 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a scheduled reference range baseline code in its canonical SRRB- form.
    static func normalizeScheduledReferenceRangeBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRRB-") {
            return clean
        }
        return "SRRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledReferenceRangeBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 82323.0, in order.
    static func scheduledReferenceRangeBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82323.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
