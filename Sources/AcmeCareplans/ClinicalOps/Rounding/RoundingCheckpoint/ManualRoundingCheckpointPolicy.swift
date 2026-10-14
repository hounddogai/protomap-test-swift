import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a manual rounding checkpoint code in its canonical MRC- form.
    static func normalizeManualRoundingCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRC-") {
            return clean
        }
        return "MRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualRoundingCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
