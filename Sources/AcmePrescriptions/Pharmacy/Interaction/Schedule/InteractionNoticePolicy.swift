import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction notice code in its canonical IN- form.
    static func normalizeInteractionNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IN-") {
            return clean
        }
        return "IN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func interactionNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 95800.0, in order.
    static func interactionNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95800.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
