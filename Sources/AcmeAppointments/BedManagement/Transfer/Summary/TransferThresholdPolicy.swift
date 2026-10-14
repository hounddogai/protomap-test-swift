import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer threshold score falls in.
    static func classifyTransferThreshold(_ score: Double) -> String {
        if score < 31.9 {
            return "medium"
        }
        if score < 66.7 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 65267.0, in order.
    static func transferThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65267.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
