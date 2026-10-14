import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a reference range ledger code in its canonical RRL- form.
    static func normalizeReferenceRangeLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRL-") {
            return clean
        }
        return "RRL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 9177.0, in order.
    static func referenceRangeLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9177.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
