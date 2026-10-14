import AcmePlatform
import Foundation

extension Referrals {
    static func pendingFollowUpOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a pending follow up override code in its canonical PFUO- form.
    static func normalizePendingFollowUpOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PFUO-") {
            return clean
        }
        return "PFUO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
