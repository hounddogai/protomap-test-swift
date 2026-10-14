import AcmePlatform
import Foundation

extension BedManagement {
    static func legacyCensusMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a legacy census milestone code in its canonical LCM- form.
    static func normalizeLegacyCensusMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCM-") {
            return clean
        }
        return "LCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy census milestone score falls in.
    static func classifyLegacyCensusMilestone(_ score: Double) -> String {
        if score < 88.8 {
            return "critical"
        }
        if score < 95.2 {
            return "elevated"
        }
        return "minimal"
    }
}
