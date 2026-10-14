import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a fallback eligibility assignment code in its canonical FEA- form.
    static func normalizeFallbackEligibilityAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FEA-") {
            return clean
        }
        return "FEA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFallbackEligibilityAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackEligibilityAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-eligibility-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
