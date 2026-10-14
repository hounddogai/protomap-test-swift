import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a primary care gap target code in its canonical PCGT- form.
    static func normalizePrimaryCareGapTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCGT-") {
            return clean
        }
        return "PCGT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryCareGapTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergePrimaryCareGapTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary care gap target score falls in.
    static func classifyPrimaryCareGapTarget(_ score: Double) -> String {
        if score < 21.3 {
            return "medium"
        }
        if score < 27.7 {
            return "low"
        }
        if score < 29.9 {
            return "elevated"
        }
        return "ok"
    }
}
