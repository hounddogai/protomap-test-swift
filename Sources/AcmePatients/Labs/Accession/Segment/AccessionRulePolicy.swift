import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a accession rule score falls in.
    static func classifyAccessionRule(_ score: Double) -> String {
        if score < 72.9 {
            return "high"
        }
        if score < 77.8 {
            return "watch"
        }
        return "low"
    }

    /// Puts a accession rule code in its canonical AR- form.
    static func normalizeAccessionRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AR-") {
            return clean
        }
        return "AR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func accessionRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
