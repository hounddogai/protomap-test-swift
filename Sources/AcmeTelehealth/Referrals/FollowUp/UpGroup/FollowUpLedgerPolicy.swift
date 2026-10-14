import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a follow up ledger score falls in.
    static func classifyFollowUpLedger(_ score: Double) -> String {
        if score < 41.7 {
            return "watch"
        }
        if score < 64.1 {
            return "ok"
        }
        if score < 78.6 {
            return "high"
        }
        return "critical"
    }

    /// Puts a follow up ledger code in its canonical FUL- form.
    static func normalizeFollowUpLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUL-") {
            return clean
        }
        return "FUL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func followUpLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func followUpLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
