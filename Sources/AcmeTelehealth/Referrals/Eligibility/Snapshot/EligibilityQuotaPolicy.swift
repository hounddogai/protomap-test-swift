import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility quota code in its canonical EQ- form.
    static func normalizeEligibilityQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EQ-") {
            return clean
        }
        return "EQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilityQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func eligibilityQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
