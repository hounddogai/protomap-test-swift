import AcmePlatform
import Foundation

extension Pharmacy {
    static func tieredSubstitutionWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredSubstitutionWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-substitution-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredSubstitutionWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
