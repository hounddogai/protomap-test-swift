import AcmePlatform
import Foundation

extension Staffing {
    static func seasonalShiftAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalShiftAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-shift-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a seasonal shift audit score falls in.
    static func classifySeasonalShiftAudit(_ score: Double) -> String {
        if score < 17.8 {
            return "ok"
        }
        if score < 28.1 {
            return "critical"
        }
        return "watch"
    }
}
