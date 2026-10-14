import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a adaptive panel snapshot score falls in.
    static func classifyAdaptivePanelSnapshot(_ score: Double) -> String {
        if score < 78.1 {
            return "low"
        }
        if score < 98.5 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptivePanelSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-panel-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptivePanelSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
