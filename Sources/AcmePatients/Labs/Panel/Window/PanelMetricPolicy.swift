import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a panel metric score falls in.
    static func classifyPanelMetric(_ score: Double) -> String {
        if score < 59.4 {
            return "minimal"
        }
        if score < 72.2 {
            return "high"
        }
        return "critical"
    }
}
