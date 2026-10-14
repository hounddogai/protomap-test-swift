import AcmePlatform
import Foundation

extension Labs {
    static func lenientReferenceRangeWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a lenient reference range window score falls in.
    static func classifyLenientReferenceRangeWindow(_ score: Double) -> String {
        if score < 21.4 {
            return "low"
        }
        if score < 60.5 {
            return "elevated"
        }
        if score < 79.6 {
            return "medium"
        }
        if score < 83.9 {
            return "watch"
        }
        return "high"
    }

    /// Puts a lenient reference range window code in its canonical LRRW- form.
    static func normalizeLenientReferenceRangeWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRW-") {
            return clean
        }
        return "LRRW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLenientReferenceRangeWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
