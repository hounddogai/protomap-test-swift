import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a lenient follow up manifest score falls in.
    static func classifyLenientFollowUpManifest(_ score: Double) -> String {
        if score < 1.7 {
            return "elevated"
        }
        if score < 3.8 {
            return "medium"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 56312.0, in order.
    static func lenientFollowUpManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 56312.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientFollowUpManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-follow-up-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
