import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a panel forecast score falls in.
    static func classifyPanelForecast(_ score: Double) -> String {
        if score < 51.1 {
            return "high"
        }
        if score < 56.0 {
            return "watch"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
