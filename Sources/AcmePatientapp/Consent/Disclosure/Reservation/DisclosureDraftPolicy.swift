import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a disclosure draft code in its canonical DD- form.
    static func normalizeDisclosureDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DD-") {
            return clean
        }
        return "DD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
