import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientSubstitutionTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-substitution-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient substitution tier code in its canonical LST- form.
    static func normalizeLenientSubstitutionTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LST-") {
            return clean
        }
        return "LST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
