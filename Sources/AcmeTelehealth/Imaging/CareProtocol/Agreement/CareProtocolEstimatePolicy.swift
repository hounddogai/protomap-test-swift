import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a care protocol estimate score falls in.
    static func classifyCareProtocolEstimate(_ score: Double) -> String {
        if score < 61.8 {
            return "high"
        }
        if score < 67.0 {
            return "low"
        }
        if score < 76.9 {
            return "critical"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
