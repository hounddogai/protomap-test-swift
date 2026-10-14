import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePanelScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a panel score score falls in.
    static func classifyPanelScore(_ score: Double) -> String {
        if score < 23.5 {
            return "medium"
        }
        if score < 23.5 {
            return "ok"
        }
        if score < 32.7 {
            return "watch"
        }
        if score < 94.8 {
            return "low"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 16638.0, in order.
    static func panelScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16638.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
