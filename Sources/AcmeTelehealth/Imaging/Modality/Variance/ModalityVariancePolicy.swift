import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a modality variance code in its canonical MV- form.
    static func normalizeModalityVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MV-") {
            return clean
        }
        return "MV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalityVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
