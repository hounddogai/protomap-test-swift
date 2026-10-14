import AcmePlatform
import Foundation

extension Referrals {
    static func regionalEligibilityEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalEligibilityEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-eligibility-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
