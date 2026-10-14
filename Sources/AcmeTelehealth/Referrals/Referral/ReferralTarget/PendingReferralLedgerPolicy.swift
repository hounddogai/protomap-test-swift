import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a pending referral ledger code in its canonical PRL- form.
    static func normalizePendingReferralLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRL-") {
            return clean
        }
        return "PRL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingReferralLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingReferralLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-referral-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingReferralLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
