import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a alert batch code in its canonical AB- form.
    static func normalizeAlertBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AB-") {
            return clean
        }
        return "AB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
