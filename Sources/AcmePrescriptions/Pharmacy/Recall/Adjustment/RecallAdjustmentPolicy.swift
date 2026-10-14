import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall adjustment code in its canonical RA- form.
    static func normalizeRecallAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a recall adjustment score falls in.
    static func classifyRecallAdjustment(_ score: Double) -> String {
        if score < 15.4 {
            return "critical"
        }
        if score < 52.6 {
            return "ok"
        }
        if score < 61.4 {
            return "elevated"
        }
        if score < 61.9 {
            return "minimal"
        }
        return "low"
    }

    static func mergeRecallAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
