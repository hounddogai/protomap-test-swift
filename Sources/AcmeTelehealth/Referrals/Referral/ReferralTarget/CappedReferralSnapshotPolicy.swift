import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a capped referral snapshot score falls in.
    static func classifyCappedReferralSnapshot(_ score: Double) -> String {
        if score < 23.1 {
            return "medium"
        }
        if score < 32.2 {
            return "high"
        }
        if score < 79.6 {
            return "minimal"
        }
        if score < 81.2 {
            return "ok"
        }
        return "low"
    }

    /// Puts a capped referral snapshot code in its canonical CRS- form.
    static func normalizeCappedReferralSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRS-") {
            return clean
        }
        return "CRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedReferralSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func cappedReferralSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
