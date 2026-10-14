import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a capped isolation schedule score falls in.
    static func classifyCappedIsolationSchedule(_ score: Double) -> String {
        if score < 6.0 {
            return "critical"
        }
        if score < 82.0 {
            return "low"
        }
        if score < 97.0 {
            return "minimal"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedIsolationSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-isolation-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
