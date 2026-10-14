import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a batched care gap bundle code in its canonical BCGB- form.
    static func normalizeBatchedCareGapBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCGB-") {
            return clean
        }
        return "BCGB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched care gap bundle score falls in.
    static func classifyBatchedCareGapBundle(_ score: Double) -> String {
        if score < 27.3 {
            return "high"
        }
        if score < 58.0 {
            return "critical"
        }
        return "low"
    }

    static func batchedCareGapBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeBatchedCareGapBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
