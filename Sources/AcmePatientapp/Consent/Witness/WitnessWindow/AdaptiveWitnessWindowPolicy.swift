import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveWitnessWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a adaptive witness window code in its canonical AWW- form.
    static func normalizeAdaptiveWitnessWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AWW-") {
            return clean
        }
        return "AWW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAdaptiveWitnessWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveWitnessWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
