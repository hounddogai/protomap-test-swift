import AcmePlatform
import Foundation

extension Consent {
    /// Puts a rolling consent form schedule code in its canonical RCFS- form.
    static func normalizeRollingConsentFormScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCFS-") {
            return clean
        }
        return "RCFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingConsentFormSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-consent-form-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
