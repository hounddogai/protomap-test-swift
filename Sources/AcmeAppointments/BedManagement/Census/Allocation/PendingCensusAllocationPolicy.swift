import AcmePlatform
import Foundation

extension BedManagement {
    static func pendingCensusAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a pending census allocation code in its canonical PCA- form.
    static func normalizePendingCensusAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCA-") {
            return clean
        }
        return "PCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
