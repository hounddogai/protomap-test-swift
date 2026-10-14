import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a capped order set exception score falls in.
    static func classifyCappedOrderSetException(_ score: Double) -> String {
        if score < 18.8 {
            return "minimal"
        }
        if score < 41.5 {
            return "high"
        }
        if score < 66.3 {
            return "critical"
        }
        if score < 86.4 {
            return "medium"
        }
        return "elevated"
    }

    static func mergeCappedOrderSetExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedOrderSetExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a capped order set exception code in its canonical COSE- form.
    static func normalizeCappedOrderSetExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("COSE-") {
            return clean
        }
        return "COSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
