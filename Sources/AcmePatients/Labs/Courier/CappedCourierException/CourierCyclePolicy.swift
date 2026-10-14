import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCourierCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("courier-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCourierCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a courier cycle score falls in.
    static func classifyCourierCycle(_ score: Double) -> String {
        if score < 27.5 {
            return "medium"
        }
        if score < 27.7 {
            return "elevated"
        }
        if score < 89.3 {
            return "critical"
        }
        return "minimal"
    }
}
