import AcmePlatform
import Foundation

extension Consent {
    /// Puts a consent form rollup code in its canonical CFR- form.
    static func normalizeConsentFormRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFR-") {
            return clean
        }
        return "CFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeConsentFormRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("consent-form-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
