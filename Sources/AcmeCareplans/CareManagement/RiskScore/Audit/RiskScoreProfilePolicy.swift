import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a risk score profile code in its canonical RSP- form.
    static func normalizeRiskScoreProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSP-") {
            return clean
        }
        return "RSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
