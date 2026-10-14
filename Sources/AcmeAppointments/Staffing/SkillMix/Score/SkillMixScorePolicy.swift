import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 81231.0, in order.
    static func skillMixScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81231.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a skill mix score code in its canonical SMS- form.
    static func normalizeSkillMixScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMS-") {
            return clean
        }
        return "SMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
