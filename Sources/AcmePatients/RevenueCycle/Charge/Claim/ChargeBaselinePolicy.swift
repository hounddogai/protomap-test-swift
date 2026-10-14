import AcmePlatform
import Foundation

extension RevenueCycle {
    static func chargeBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeChargeBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeChargeBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("charge-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
