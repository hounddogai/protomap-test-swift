import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality budget score falls in.
    static func classifyModalityBudget(_ score: Double) -> String {
        if score < 6.7 {
            return "watch"
        }
        if score < 47.8 {
            return "minimal"
        }
        if score < 50.2 {
            return "critical"
        }
        if score < 55.8 {
            return "high"
        }
        return "medium"
    }

    static func modalityBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeModalityBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a modality budget code in its canonical MB- form.
    static func normalizeModalityBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MB-") {
            return clean
        }
        return "MB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
