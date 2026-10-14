import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a seasonal care protocol baseline score falls in.
    static func classifySeasonalCareProtocolBaseline(_ score: Double) -> String {
        if score < 7.4 {
            return "critical"
        }
        if score < 23.8 {
            return "low"
        }
        if score < 66.1 {
            return "high"
        }
        return "elevated"
    }

    static func seasonalCareProtocolBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCareProtocolBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-care-protocol-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
