import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalPrioritySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-priority-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global priority slot score falls in.
    static func classifyGlobalPrioritySlot(_ score: Double) -> String {
        if score < 26.6 {
            return "elevated"
        }
        if score < 61.6 {
            return "high"
        }
        if score < 93.5 {
            return "watch"
        }
        if score < 98.6 {
            return "minimal"
        }
        return "medium"
    }
}
