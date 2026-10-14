import AcmePlatform
import Foundation

extension Labs {
    /// Puts a pending reference range profile code in its canonical PRRP- form.
    static func normalizePendingReferenceRangeProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRRP-") {
            return clean
        }
        return "PRRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingReferenceRangeProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-reference-range-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 91780.0, in order.
    static func pendingReferenceRangeProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91780.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
