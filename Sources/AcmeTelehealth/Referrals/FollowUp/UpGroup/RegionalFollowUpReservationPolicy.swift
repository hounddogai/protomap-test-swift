import AcmePlatform
import Foundation

extension Referrals {
    static func mergeRegionalFollowUpReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalFollowUpReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-follow-up-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional follow up reservation code in its canonical RFUR- form.
    static func normalizeRegionalFollowUpReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFUR-") {
            return clean
        }
        return "RFUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
