import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a lenient rounding profile code in its canonical LRP- form.
    static func normalizeLenientRoundingProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRP-") {
            return clean
        }
        return "LRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientRoundingProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-rounding-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
