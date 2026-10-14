import AcmePlatform
import Foundation

extension Referrals {
    static func batchedSlotRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a batched slot record code in its canonical BSR- form.
    static func normalizeBatchedSlotRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSR-") {
            return clean
        }
        return "BSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
