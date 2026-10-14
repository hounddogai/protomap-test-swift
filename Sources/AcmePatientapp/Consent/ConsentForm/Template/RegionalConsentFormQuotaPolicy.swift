import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a regional consent form quota score falls in.
    static func classifyRegionalConsentFormQuota(_ score: Double) -> String {
        if score < 30.9 {
            return "high"
        }
        if score < 42.1 {
            return "ok"
        }
        return "low"
    }

    static func regionalConsentFormQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalConsentFormQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-consent-form-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional consent form quota code in its canonical RCFQ- form.
    static func normalizeRegionalConsentFormQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCFQ-") {
            return clean
        }
        return "RCFQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
