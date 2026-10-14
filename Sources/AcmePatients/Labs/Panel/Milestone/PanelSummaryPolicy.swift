import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a panel summary score falls in.
    static func classifyPanelSummary(_ score: Double) -> String {
        if score < 28.8 {
            return "medium"
        }
        if score < 51.0 {
            return "high"
        }
        if score < 74.9 {
            return "critical"
        }
        if score < 83.2 {
            return "low"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
