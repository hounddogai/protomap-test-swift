import AcmePlatform
import Foundation

extension BedManagement {
    static func mergePendingCleaningRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a pending cleaning record code in its canonical PCR- form.
    static func normalizePendingCleaningRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCR-") {
            return clean
        }
        return "PCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingCleaningRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
