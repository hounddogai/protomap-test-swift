import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a legacy handoff ledger code in its canonical LHL- form.
    static func normalizeLegacyHandoffLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LHL-") {
            return clean
        }
        return "LHL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyHandoffLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-handoff-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyHandoffLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 7540.0, in order.
    static func legacyHandoffLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7540.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
