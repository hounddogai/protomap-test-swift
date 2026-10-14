import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a global eligibility variance code in its canonical GEV- form.
    static func normalizeGlobalEligibilityVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GEV-") {
            return clean
        }
        return "GEV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalEligibilityVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-eligibility-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 3131.0, in order.
    static func globalEligibilityVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3131.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalEligibilityVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
