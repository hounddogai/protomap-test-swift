import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen assignment score falls in.
    static func classifySpecimenAssignment(_ score: Double) -> String {
        if score < 43.8 {
            return "low"
        }
        if score < 65.6 {
            return "medium"
        }
        if score < 72.8 {
            return "high"
        }
        if score < 75.1 {
            return "elevated"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
