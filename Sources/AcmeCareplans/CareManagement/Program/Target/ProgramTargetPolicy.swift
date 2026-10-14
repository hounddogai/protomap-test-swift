import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a program target score falls in.
    static func classifyProgramTarget(_ score: Double) -> String {
        if score < 18.5 {
            return "minimal"
        }
        if score < 52.2 {
            return "high"
        }
        if score < 91.6 {
            return "critical"
        }
        return "elevated"
    }

    static func programTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProgramTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("program-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
