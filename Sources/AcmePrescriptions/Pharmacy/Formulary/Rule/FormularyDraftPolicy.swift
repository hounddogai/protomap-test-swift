import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFormularyDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("formulary-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 49606.0, in order.
    static func formularyDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49606.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a formulary draft code in its canonical FD- form.
    static func normalizeFormularyDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FD-") {
            return clean
        }
        return "FD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
