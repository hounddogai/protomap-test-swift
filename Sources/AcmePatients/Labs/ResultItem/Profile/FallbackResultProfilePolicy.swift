import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackResultProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-result-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback result profile code in its canonical FRP- form.
    static func normalizeFallbackResultProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRP-") {
            return clean
        }
        return "FRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
