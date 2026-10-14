import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeSeasonalCareGapSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalCareGapSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a seasonal care gap snapshot code in its canonical SCGS- form.
    static func normalizeSeasonalCareGapSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCGS-") {
            return clean
        }
        return "SCGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
