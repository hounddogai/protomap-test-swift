import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall rule code in its canonical RR- form.
    static func normalizeRecallRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a recall rule score falls in.
    static func classifyRecallRule(_ score: Double) -> String {
        if score < 18.3 {
            return "medium"
        }
        if score < 27.0 {
            return "minimal"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
