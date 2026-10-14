import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a legacy census allocation code in its canonical LCA- form.
    static func normalizeLegacyCensusAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCA-") {
            return clean
        }
        return "LCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyCensusAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
