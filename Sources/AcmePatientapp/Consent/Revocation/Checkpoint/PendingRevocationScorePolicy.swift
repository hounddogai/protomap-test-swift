import AcmePlatform
import Foundation

extension Consent {
    /// Puts a pending revocation score code in its canonical PRS- form.
    static func normalizePendingRevocationScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRS-") {
            return clean
        }
        return "PRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingRevocationScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
