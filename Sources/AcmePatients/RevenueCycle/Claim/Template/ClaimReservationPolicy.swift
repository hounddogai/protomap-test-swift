import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a claim reservation score falls in.
    static func classifyClaimReservation(_ score: Double) -> String {
        if score < 35.0 {
            return "watch"
        }
        if score < 50.9 {
            return "medium"
        }
        if score < 75.5 {
            return "minimal"
        }
        if score < 76.7 {
            return "critical"
        }
        return "low"
    }

    /// Puts a claim reservation code in its canonical CR- form.
    static func normalizeClaimReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 63515.0, in order.
    static func claimReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63515.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
