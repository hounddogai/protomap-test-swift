import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a capped slot bundle score falls in.
    static func classifyCappedSlotBundle(_ score: Double) -> String {
        if score < 7.9 {
            return "medium"
        }
        if score < 16.4 {
            return "ok"
        }
        if score < 86.4 {
            return "high"
        }
        return "elevated"
    }

    /// Puts a capped slot bundle code in its canonical CSB- form.
    static func normalizeCappedSlotBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSB-") {
            return clean
        }
        return "CSB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
