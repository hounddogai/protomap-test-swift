import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingConsentFormAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-consent-form-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 66923.0, in order.
    static func pendingConsentFormAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66923.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingConsentFormAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a pending consent form allocation code in its canonical PCFA- form.
    static func normalizePendingConsentFormAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCFA-") {
            return clean
        }
        return "PCFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
