import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a pending charge draft code in its canonical PCD- form.
    static func normalizePendingChargeDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCD-") {
            return clean
        }
        return "PCD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 54391.0, in order.
    static func pendingChargeDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54391.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingChargeDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-charge-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending charge draft score falls in.
    static func classifyPendingChargeDraft(_ score: Double) -> String {
        if score < 3.8 {
            return "minimal"
        }
        if score < 60.2 {
            return "critical"
        }
        if score < 89.2 {
            return "elevated"
        }
        return "high"
    }
}
