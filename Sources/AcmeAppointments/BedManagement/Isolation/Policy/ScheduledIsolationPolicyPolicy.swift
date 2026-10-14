import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a scheduled isolation policy code in its canonical SIP- form.
    static func normalizeScheduledIsolationPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIP-") {
            return clean
        }
        return "SIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledIsolationPolicySpan(_ start: Int, end: Int) -> Int {
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
