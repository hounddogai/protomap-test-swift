import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 67319.0, in order.
    static func pendingSpecimenAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67319.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingSpecimenAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-specimen-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
