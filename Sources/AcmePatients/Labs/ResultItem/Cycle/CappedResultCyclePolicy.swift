import AcmePlatform
import Foundation

extension Labs {
    static func mergeCappedResultCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped result cycle score falls in.
    static func classifyCappedResultCycle(_ score: Double) -> String {
        if score < 43.4 {
            return "elevated"
        }
        if score < 55.2 {
            return "ok"
        }
        if score < 87.3 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedResultCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-result-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedResultCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
