import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 80163.0, in order.
    static func defaultTransferAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80163.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultTransferAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-transfer-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default transfer agreement score falls in.
    static func classifyDefaultTransferAgreement(_ score: Double) -> String {
        if score < 37.2 {
            return "elevated"
        }
        if score < 46.7 {
            return "watch"
        }
        return "minimal"
    }
}
