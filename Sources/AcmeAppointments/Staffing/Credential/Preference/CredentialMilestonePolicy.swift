import AcmePlatform
import Foundation

extension Staffing {
    static func credentialMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a credential milestone score falls in.
    static func classifyCredentialMilestone(_ score: Double) -> String {
        if score < 68.0 {
            return "watch"
        }
        if score < 94.6 {
            return "minimal"
        }
        return "elevated"
    }

    static func credentialMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a credential milestone code in its canonical CM- form.
    static func normalizeCredentialMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CM-") {
            return clean
        }
        return "CM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
