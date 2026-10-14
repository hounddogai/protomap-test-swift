import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a regional study baseline score falls in.
    static func classifyRegionalStudyBaseline(_ score: Double) -> String {
        if score < 6.7 {
            return "watch"
        }
        if score < 38.5 {
            return "elevated"
        }
        if score < 64.1 {
            return "medium"
        }
        if score < 76.7 {
            return "critical"
        }
        return "low"
    }

    /// Puts a regional study baseline code in its canonical RSB- form.
    static func normalizeRegionalStudyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSB-") {
            return clean
        }
        return "RSB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalStudyBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 5978.0, in order.
    static func regionalStudyBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5978.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
