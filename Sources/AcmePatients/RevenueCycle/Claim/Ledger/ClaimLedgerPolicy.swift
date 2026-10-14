import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a claim ledger code in its canonical CL- form.
    static func normalizeClaimLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CL-") {
            return clean
        }
        return "CL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a claim ledger score falls in.
    static func classifyClaimLedger(_ score: Double) -> String {
        if score < 2.8 {
            return "high"
        }
        if score < 7.8 {
            return "elevated"
        }
        if score < 28.5 {
            return "critical"
        }
        if score < 34.1 {
            return "medium"
        }
        return "ok"
    }

    static func claimLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
