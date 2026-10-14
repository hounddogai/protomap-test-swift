import AcmePlatform
import Foundation

extension Imaging {
    static func priorityQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a priority quota code in its canonical PQ- form.
    static func normalizePriorityQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PQ-") {
            return clean
        }
        return "PQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 19253.0, in order.
    static func priorityQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19253.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
