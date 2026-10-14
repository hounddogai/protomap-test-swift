import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a legacy handoff request code in its canonical LHR- form.
    static func normalizeLegacyHandoffRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LHR-") {
            return clean
        }
        return "LHR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyHandoffRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func legacyHandoffRequestSpan(_ start: Int, end: Int) -> Int {
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
