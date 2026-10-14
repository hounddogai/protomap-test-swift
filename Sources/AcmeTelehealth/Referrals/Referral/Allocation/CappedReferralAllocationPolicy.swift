import AcmePlatform
import Foundation

extension Referrals {
    static func cappedReferralAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a capped referral allocation code in its canonical CRA- form.
    static func normalizeCappedReferralAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRA-") {
            return clean
        }
        return "CRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedReferralAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-referral-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
