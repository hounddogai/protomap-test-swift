import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a batched skill mix cycle code in its canonical BSMC- form.
    static func normalizeBatchedSkillMixCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSMC-") {
            return clean
        }
        return "BSMC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedSkillMixCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func batchedSkillMixCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedSkillMixCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-skill-mix-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
