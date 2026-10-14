import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a language cycle code in its canonical LC- form.
    static func normalizeLanguageCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LC-") {
            return clean
        }
        return "LC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
