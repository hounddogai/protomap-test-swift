import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func credentialAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
