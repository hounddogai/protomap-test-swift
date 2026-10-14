import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a transfer template code in its canonical TT- form.
    static func normalizeTransferTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TT-") {
            return clean
        }
        return "TT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func transferTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
