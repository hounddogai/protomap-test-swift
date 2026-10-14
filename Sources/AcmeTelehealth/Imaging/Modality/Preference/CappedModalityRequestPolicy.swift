import AcmePlatform
import Foundation

extension Imaging {
    static func mergeCappedModalityRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped modality request code in its canonical CMR- form.
    static func normalizeCappedModalityRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CMR-") {
            return clean
        }
        return "CMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped modality request score falls in.
    static func classifyCappedModalityRequest(_ score: Double) -> String {
        if score < 14.7 {
            return "low"
        }
        if score < 39.5 {
            return "medium"
        }
        if score < 55.0 {
            return "critical"
        }
        return "ok"
    }

    static func cappedModalityRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
