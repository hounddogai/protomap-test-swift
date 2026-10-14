import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 37581.0, in order.
    static func skillMixReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37581.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func skillMixReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a skill mix reservation code in its canonical SMR- form.
    static func normalizeSkillMixReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMR-") {
            return clean
        }
        return "SMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
