import AcmePlatform
import Foundation

extension Referrals {
    static func followUpAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func followUpAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a follow up allocation score falls in.
    static func classifyFollowUpAllocation(_ score: Double) -> String {
        if score < 47.9 {
            return "elevated"
        }
        if score < 54.3 {
            return "critical"
        }
        if score < 79.7 {
            return "ok"
        }
        if score < 95.4 {
            return "high"
        }
        return "medium"
    }

    /// Puts a follow up allocation code in its canonical FUA- form.
    static func normalizeFollowUpAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUA-") {
            return clean
        }
        return "FUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
