import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveBedBoardReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a adaptive bed board review code in its canonical ABBR- form.
    static func normalizeAdaptiveBedBoardReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ABBR-") {
            return clean
        }
        return "ABBR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAdaptiveBedBoardReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveBedBoardReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
