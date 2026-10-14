import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a skill mix cycle code in its canonical SMC- form.
    static func normalizeSkillMixCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMC-") {
            return clean
        }
        return "SMC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func skillMixCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 4785.0, in order.
    static func skillMixCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4785.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
