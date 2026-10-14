import AcmePlatform
import Foundation

extension Imaging {
    static func cappedModalityMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func mergeCappedModalityMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped modality mapping code in its canonical CMM- form.
    static func normalizeCappedModalityMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CMM-") {
            return clean
        }
        return "CMM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedModalityMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
