import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedNetworkRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-network-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedNetworkRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a capped network record score falls in.
    static func classifyCappedNetworkRecord(_ score: Double) -> String {
        if score < 21.5 {
            return "elevated"
        }
        if score < 54.5 {
            return "watch"
        }
        if score < 63.7 {
            return "high"
        }
        if score < 76.2 {
            return "minimal"
        }
        return "critical"
    }
}
