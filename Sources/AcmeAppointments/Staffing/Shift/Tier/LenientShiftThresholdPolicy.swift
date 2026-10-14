import AcmePlatform
import Foundation

extension Staffing {
    static func lenientShiftThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func mergeLenientShiftThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient shift threshold score falls in.
    static func classifyLenientShiftThreshold(_ score: Double) -> String {
        if score < 1.9 {
            return "low"
        }
        if score < 22.7 {
            return "critical"
        }
        if score < 32.3 {
            return "medium"
        }
        return "minimal"
    }

    /// Puts a lenient shift threshold code in its canonical LST- form.
    static func normalizeLenientShiftThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LST-") {
            return clean
        }
        return "LST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
