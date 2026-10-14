import AcmePlatform
import Foundation

extension Consent {
    /// Puts a capped consent form rule code in its canonical CCFR- form.
    static func normalizeCappedConsentFormRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCFR-") {
            return clean
        }
        return "CCFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedConsentFormRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedConsentFormRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-consent-form-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
