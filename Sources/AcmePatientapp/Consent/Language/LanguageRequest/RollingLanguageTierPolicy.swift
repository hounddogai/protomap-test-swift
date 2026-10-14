import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingLanguageTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-language-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling language tier code in its canonical RLT- form.
    static func normalizeRollingLanguageTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RLT-") {
            return clean
        }
        return "RLT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
