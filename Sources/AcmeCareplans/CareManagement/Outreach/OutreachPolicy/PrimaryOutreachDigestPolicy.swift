import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a primary outreach digest code in its canonical POD- form.
    static func normalizePrimaryOutreachDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POD-") {
            return clean
        }
        return "POD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryOutreachDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryOutreachDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-outreach-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
