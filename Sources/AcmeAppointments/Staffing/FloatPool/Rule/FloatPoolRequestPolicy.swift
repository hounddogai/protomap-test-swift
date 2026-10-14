import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeFloatPoolRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func floatPoolRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a float pool request score falls in.
    static func classifyFloatPoolRequest(_ score: Double) -> String {
        if score < 25.1 {
            return "medium"
        }
        if score < 80.7 {
            return "high"
        }
        if score < 97.0 {
            return "low"
        }
        if score < 99.2 {
            return "ok"
        }
        return "minimal"
    }
}
