import AcmePlatform
import Foundation

extension Staffing {
    static func regionalShiftBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalShiftBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-shift-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalShiftBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
