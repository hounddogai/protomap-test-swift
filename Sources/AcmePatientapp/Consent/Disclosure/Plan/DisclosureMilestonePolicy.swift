import AcmePlatform
import Foundation

extension Consent {
    static func disclosureMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a disclosure milestone code in its canonical DM- form.
    static func normalizeDisclosureMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DM-") {
            return clean
        }
        return "DM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
