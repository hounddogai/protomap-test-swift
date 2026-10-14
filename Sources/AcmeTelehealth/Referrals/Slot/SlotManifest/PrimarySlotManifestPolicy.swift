import AcmePlatform
import Foundation

extension Referrals {
    static func primarySlotManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimarySlotManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-slot-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 96830.0, in order.
    static func primarySlotManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96830.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
