import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form slot score falls in.
    static func classifyConsentFormSlot(_ score: Double) -> String {
        if score < 90.0 {
            return "ok"
        }
        if score < 95.0 {
            return "elevated"
        }
        return "watch"
    }

    /// Puts a consent form slot code in its canonical CFS- form.
    static func normalizeConsentFormSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFS-") {
            return clean
        }
        return "CFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeConsentFormSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("consent-form-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
