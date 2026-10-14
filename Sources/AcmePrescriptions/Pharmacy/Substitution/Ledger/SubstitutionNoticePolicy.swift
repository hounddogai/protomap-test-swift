import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeSubstitutionNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a substitution notice code in its canonical SN- form.
    static func normalizeSubstitutionNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SN-") {
            return clean
        }
        return "SN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func substitutionNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func substitutionNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
