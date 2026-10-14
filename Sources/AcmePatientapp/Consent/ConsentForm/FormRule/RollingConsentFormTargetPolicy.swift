import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a rolling consent form target score falls in.
    static func classifyRollingConsentFormTarget(_ score: Double) -> String {
        if score < 42.0 {
            return "low"
        }
        if score < 61.5 {
            return "high"
        }
        if score < 70.4 {
            return "minimal"
        }
        if score < 86.3 {
            return "elevated"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 44878.0, in order.
    static func rollingConsentFormTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44878.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingConsentFormTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-consent-form-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling consent form target code in its canonical RCFT- form.
    static func normalizeRollingConsentFormTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCFT-") {
            return clean
        }
        return "RCFT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
