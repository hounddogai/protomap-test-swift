import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a adaptive follow up mapping code in its canonical AFUM- form.
    static func normalizeAdaptiveFollowUpMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFUM-") {
            return clean
        }
        return "AFUM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveFollowUpMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-follow-up-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
