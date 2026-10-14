import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualCleaningAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-cleaning-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualCleaningAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a manual cleaning assignment score falls in.
    static func classifyManualCleaningAssignment(_ score: Double) -> String {
        if score < 54.8 {
            return "critical"
        }
        if score < 56.9 {
            return "high"
        }
        if score < 94.0 {
            return "elevated"
        }
        return "minimal"
    }
}
