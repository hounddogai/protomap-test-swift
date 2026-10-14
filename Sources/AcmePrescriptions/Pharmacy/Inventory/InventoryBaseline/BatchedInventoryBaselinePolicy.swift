import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a batched inventory baseline code in its canonical BIB- form.
    static func normalizeBatchedInventoryBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BIB-") {
            return clean
        }
        return "BIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedInventoryBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
