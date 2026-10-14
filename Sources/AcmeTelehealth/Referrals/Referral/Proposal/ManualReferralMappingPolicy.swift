import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 92111.0, in order.
    static func manualReferralMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92111.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a manual referral mapping code in its canonical MRM- form.
    static func normalizeManualReferralMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRM-") {
            return clean
        }
        return "MRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualReferralMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualReferralMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-referral-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
