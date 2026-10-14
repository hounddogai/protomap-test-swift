import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a care protocol claim score falls in.
    static func classifyCareProtocolClaim(_ score: Double) -> String {
        if score < 29.0 {
            return "medium"
        }
        if score < 43.7 {
            return "minimal"
        }
        if score < 71.0 {
            return "low"
        }
        if score < 98.5 {
            return "critical"
        }
        return "high"
    }

    static func careProtocolClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
