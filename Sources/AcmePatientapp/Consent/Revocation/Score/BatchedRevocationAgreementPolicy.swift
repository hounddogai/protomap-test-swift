import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a batched revocation agreement score falls in.
    static func classifyBatchedRevocationAgreement(_ score: Double) -> String {
        if score < 45.8 {
            return "minimal"
        }
        if score < 48.8 {
            return "elevated"
        }
        if score < 81.4 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedRevocationAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-revocation-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeBatchedRevocationAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
