import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryLanguageAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-language-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary language assignment code in its canonical PLA- form.
    static func normalizePrimaryLanguageAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PLA-") {
            return clean
        }
        return "PLA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 90855.0, in order.
    static func primaryLanguageAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90855.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary language assignment score falls in.
    static func classifyPrimaryLanguageAssignment(_ score: Double) -> String {
        if score < 38.2 {
            return "elevated"
        }
        if score < 97.8 {
            return "minimal"
        }
        return "watch"
    }
}
