import AcmePlatform
import Foundation

extension Consent {
    /// Puts a primary consent form profile code in its canonical PCFP- form.
    static func normalizePrimaryConsentFormProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCFP-") {
            return clean
        }
        return "PCFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryConsentFormProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-consent-form-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary consent form profile score falls in.
    static func classifyPrimaryConsentFormProfile(_ score: Double) -> String {
        if score < 5.8 {
            return "medium"
        }
        if score < 68.9 {
            return "ok"
        }
        if score < 81.4 {
            return "low"
        }
        return "minimal"
    }
}
