import AcmePlatform
import Foundation

extension Labs {
    static func strictAccessionAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a strict accession assignment score falls in.
    static func classifyStrictAccessionAssignment(_ score: Double) -> String {
        if score < 62.0 {
            return "ok"
        }
        if score < 65.4 {
            return "low"
        }
        if score < 79.0 {
            return "high"
        }
        if score < 83.7 {
            return "medium"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictAccessionAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-accession-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictAccessionAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
