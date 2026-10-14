import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a rolling skill mix request code in its canonical RSMR- form.
    static func normalizeRollingSkillMixRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSMR-") {
            return clean
        }
        return "RSMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingSkillMixRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-skill-mix-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
