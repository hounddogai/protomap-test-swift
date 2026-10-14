import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func careProtocolNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a care protocol notice score falls in.
    static func classifyCareProtocolNotice(_ score: Double) -> String {
        if score < 1.4 {
            return "watch"
        }
        if score < 11.3 {
            return "ok"
        }
        if score < 48.0 {
            return "medium"
        }
        if score < 77.0 {
            return "elevated"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
