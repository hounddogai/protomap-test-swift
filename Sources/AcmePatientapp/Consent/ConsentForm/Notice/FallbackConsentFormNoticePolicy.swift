import AcmePlatform
import Foundation

extension Consent {
    static func fallbackConsentFormNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackConsentFormNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-consent-form-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback consent form notice code in its canonical FCFN- form.
    static func normalizeFallbackConsentFormNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCFN-") {
            return clean
        }
        return "FCFN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackConsentFormNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
