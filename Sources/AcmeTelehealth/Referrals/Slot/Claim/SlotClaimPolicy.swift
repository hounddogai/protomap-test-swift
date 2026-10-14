import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 37213.0, in order.
    static func slotClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37213.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func slotClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a slot claim code in its canonical SC- form.
    static func normalizeSlotClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SC-") {
            return clean
        }
        return "SC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
