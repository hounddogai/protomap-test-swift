import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a primary assessment policy score falls in.
    static func classifyPrimaryAssessmentPolicy(_ score: Double) -> String {
        if score < 18.4 {
            return "minimal"
        }
        if score < 19.4 {
            return "critical"
        }
        if score < 57.1 {
            return "ok"
        }
        if score < 72.4 {
            return "elevated"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryAssessmentPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-assessment-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryAssessmentPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a primary assessment policy code in its canonical PAP- form.
    static func normalizePrimaryAssessmentPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAP-") {
            return clean
        }
        return "PAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
