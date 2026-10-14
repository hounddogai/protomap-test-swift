import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientProxyVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-proxy-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient proxy variance code in its canonical LPV- form.
    static func normalizeLenientProxyVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LPV-") {
            return clean
        }
        return "LPV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 20079.0, in order.
    static func lenientProxyVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20079.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientProxyVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
