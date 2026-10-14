import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a tiered panel group score falls in.
    static func classifyTieredPanelGroup(_ score: Double) -> String {
        if score < 34.1 {
            return "critical"
        }
        if score < 37.6 {
            return "medium"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredPanelGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-panel-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
