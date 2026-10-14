import AcmePlatform
import Foundation

extension Labs {
    /// Puts a adaptive result request code in its canonical ARR- form.
    static func normalizeAdaptiveResultRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARR-") {
            return clean
        }
        return "ARR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive result request score falls in.
    static func classifyAdaptiveResultRequest(_ score: Double) -> String {
        if score < 51.1 {
            return "critical"
        }
        if score < 83.5 {
            return "elevated"
        }
        return "high"
    }

    static func mergeAdaptiveResultRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
