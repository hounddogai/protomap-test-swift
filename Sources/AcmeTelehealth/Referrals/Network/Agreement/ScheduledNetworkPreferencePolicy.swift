import AcmePlatform
import Foundation

extension Referrals {
    static func scheduledNetworkPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a scheduled network preference code in its canonical SNP- form.
    static func normalizeScheduledNetworkPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SNP-") {
            return clean
        }
        return "SNP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
