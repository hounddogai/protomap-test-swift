import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackAccessionNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-accession-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackAccessionNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
