import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalRevocationAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-revocation-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional revocation agreement code in its canonical RRA- form.
    static func normalizeRegionalRevocationAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRA-") {
            return clean
        }
        return "RRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
