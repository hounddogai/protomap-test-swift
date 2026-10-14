import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a fallback panel group score falls in.
    static func classifyFallbackPanelGroup(_ score: Double) -> String {
        if score < 52.3 {
            return "watch"
        }
        if score < 81.0 {
            return "minimal"
        }
        if score < 94.5 {
            return "ok"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 84970.0, in order.
    static func fallbackPanelGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84970.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackPanelGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackPanelGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-panel-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
