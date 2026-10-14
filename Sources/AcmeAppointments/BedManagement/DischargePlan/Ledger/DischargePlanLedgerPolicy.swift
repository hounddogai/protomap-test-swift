import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a discharge plan ledger code in its canonical DPL- form.
    static func normalizeDischargePlanLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPL-") {
            return clean
        }
        return "DPL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dischargePlanLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
