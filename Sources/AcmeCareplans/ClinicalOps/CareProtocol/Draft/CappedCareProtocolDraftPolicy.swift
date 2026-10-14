import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCareProtocolDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-care-protocol-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedCareProtocolDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
