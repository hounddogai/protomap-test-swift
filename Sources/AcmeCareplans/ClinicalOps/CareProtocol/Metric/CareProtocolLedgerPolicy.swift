import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 72888.0, in order.
    static func careProtocolLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72888.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCareProtocolLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
