import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a tiered remittance exception code in its canonical TRE- form.
    static func normalizeTieredRemittanceExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRE-") {
            return clean
        }
        return "TRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredRemittanceExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 7222.0, in order.
    static func tieredRemittanceExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7222.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredRemittanceException() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-remittance-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
