import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a assessment digest code in its canonical AD- form.
    static func normalizeAssessmentDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AD-") {
            return clean
        }
        return "AD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
