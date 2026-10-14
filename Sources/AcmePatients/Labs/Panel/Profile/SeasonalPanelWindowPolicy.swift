import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a seasonal panel window score falls in.
    static func classifySeasonalPanelWindow(_ score: Double) -> String {
        if score < 38.0 {
            return "minimal"
        }
        if score < 54.8 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalPanelWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-panel-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalPanelWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func seasonalPanelWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
