import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a fallback denial rule code in its canonical FDR- form.
    static func normalizeFallbackDenialRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDR-") {
            return clean
        }
        return "FDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackDenialRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-denial-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
