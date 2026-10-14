import AcmePlatform
import Foundation

extension Labs {
    /// Puts a capped reference range estimate code in its canonical CRRE- form.
    static func normalizeCappedReferenceRangeEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRRE-") {
            return clean
        }
        return "CRRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedReferenceRangeEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedReferenceRangeEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func cappedReferenceRangeEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.2
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
