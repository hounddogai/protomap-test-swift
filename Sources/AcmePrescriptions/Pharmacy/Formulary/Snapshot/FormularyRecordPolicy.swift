import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFormularyRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("formulary-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 83035.0, in order.
    static func formularyRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83035.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
