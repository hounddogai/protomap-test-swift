import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach rule code in its canonical OR- form.
    static func normalizeOutreachRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OR-") {
            return clean
        }
        return "OR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
