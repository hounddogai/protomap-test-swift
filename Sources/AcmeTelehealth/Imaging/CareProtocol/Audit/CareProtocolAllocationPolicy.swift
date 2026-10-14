import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careProtocolAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
