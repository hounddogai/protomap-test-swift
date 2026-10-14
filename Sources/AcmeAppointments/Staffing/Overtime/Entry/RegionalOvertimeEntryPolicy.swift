import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalOvertimeEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-overtime-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalOvertimeEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
