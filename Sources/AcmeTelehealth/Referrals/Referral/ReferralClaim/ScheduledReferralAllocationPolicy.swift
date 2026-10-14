import AcmePlatform
import Foundation

extension Referrals {
    static func scheduledReferralAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledReferralAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-referral-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled referral allocation code in its canonical SRA- form.
    static func normalizeScheduledReferralAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRA-") {
            return clean
        }
        return "SRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledReferralAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
