import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a alert record score falls in.
    static func classifyAlertRecord(_ score: Double) -> String {
        if score < 54.7 {
            return "low"
        }
        if score < 63.4 {
            return "elevated"
        }
        if score < 68.7 {
            return "medium"
        }
        return "critical"
    }

    static func mergeAlertRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a alert record code in its canonical AR- form.
    static func normalizeAlertRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AR-") {
            return clean
        }
        return "AR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
