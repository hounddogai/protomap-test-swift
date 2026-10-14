import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a claim milestone code in its canonical CM- form.
    static func normalizeClaimMilestoneCode(_ code: String) -> String {
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
