import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy reference range summary code in its canonical LRRS- form.
    static func normalizeLegacyReferenceRangeSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRS-") {
            return clean
        }
        return "LRRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyReferenceRangeSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func legacyReferenceRangeSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
