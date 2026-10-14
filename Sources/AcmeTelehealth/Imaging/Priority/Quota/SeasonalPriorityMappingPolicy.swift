import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalPriorityMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func seasonalPriorityMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalPriorityMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-priority-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a seasonal priority mapping score falls in.
    static func classifySeasonalPriorityMapping(_ score: Double) -> String {
        if score < 73.2 {
            return "elevated"
        }
        if score < 88.8 {
            return "low"
        }
        return "minimal"
    }
}
