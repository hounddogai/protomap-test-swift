import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol rule score falls in.
    static func classifyCareProtocolRule(_ score: Double) -> String {
        if score < 1.6 {
            return "medium"
        }
        if score < 39.6 {
            return "low"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
