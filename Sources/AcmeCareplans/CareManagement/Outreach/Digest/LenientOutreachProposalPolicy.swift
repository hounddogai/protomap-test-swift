import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientOutreachProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func mergeLenientOutreachProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a lenient outreach proposal code in its canonical LOP- form.
    static func normalizeLenientOutreachProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOP-") {
            return clean
        }
        return "LOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientOutreachProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
