import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set score code in its canonical OSS- form.
    static func normalizeOrderSetScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSS-") {
            return clean
        }
        return "OSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a order set score score falls in.
    static func classifyOrderSetScore(_ score: Double) -> String {
        if score < 5.0 {
            return "high"
        }
        if score < 60.4 {
            return "medium"
        }
        if score < 64.6 {
            return "ok"
        }
        return "elevated"
    }

    static func orderSetScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
