import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackChargeException() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-charge-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback charge exception code in its canonical FCE- form.
    static func normalizeFallbackChargeExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCE-") {
            return clean
        }
        return "FCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackChargeExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 24809.0, in order.
    static func fallbackChargeExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24809.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
