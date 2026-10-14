import AcmePlatform
import Foundation

extension Consent {
    static func scheduledConsentFormAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a scheduled consent form allocation score falls in.
    static func classifyScheduledConsentFormAllocation(_ score: Double) -> String {
        if score < 90.0 {
            return "critical"
        }
        if score < 91.6 {
            return "elevated"
        }
        return "ok"
    }

    static func scheduledConsentFormAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
