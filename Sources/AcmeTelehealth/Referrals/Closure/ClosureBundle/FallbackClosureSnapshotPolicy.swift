import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a fallback closure snapshot code in its canonical FCS- form.
    static func normalizeFallbackClosureSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCS-") {
            return clean
        }
        return "FCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 12081.0, in order.
    static func fallbackClosureSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12081.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackClosureSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-closure-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
