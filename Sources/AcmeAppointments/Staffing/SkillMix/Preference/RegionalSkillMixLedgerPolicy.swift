import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 72345.0, in order.
    static func regionalSkillMixLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72345.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalSkillMixLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func regionalSkillMixLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalSkillMixLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-skill-mix-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
