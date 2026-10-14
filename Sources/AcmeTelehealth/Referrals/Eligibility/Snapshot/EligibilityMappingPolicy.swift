import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility mapping code in its canonical EM- form.
    static func normalizeEligibilityMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EM-") {
            return clean
        }
        return "EM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilityMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a eligibility mapping score falls in.
    static func classifyEligibilityMapping(_ score: Double) -> String {
        if score < 11.9 {
            return "ok"
        }
        if score < 53.7 {
            return "low"
        }
        return "minimal"
    }
}
