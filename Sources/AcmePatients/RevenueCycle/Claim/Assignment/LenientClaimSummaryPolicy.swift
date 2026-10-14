import AcmePlatform
import Foundation

extension RevenueCycle {
    static func lenientClaimSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a lenient claim summary code in its canonical LCS- form.
    static func normalizeLenientClaimSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCS-") {
            return clean
        }
        return "LCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientClaimSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-claim-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 48403.0, in order.
    static func lenientClaimSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48403.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
