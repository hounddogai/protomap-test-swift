import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a program cycle score falls in.
    static func classifyProgramCycle(_ score: Double) -> String {
        if score < 13.5 {
            return "watch"
        }
        if score < 28.4 {
            return "elevated"
        }
        if score < 70.1 {
            return "minimal"
        }
        if score < 95.6 {
            return "low"
        }
        return "high"
    }

    static func programCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProgramCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("program-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
