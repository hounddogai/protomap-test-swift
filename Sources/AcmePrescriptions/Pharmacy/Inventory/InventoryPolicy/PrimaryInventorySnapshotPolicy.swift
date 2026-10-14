import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a primary inventory snapshot code in its canonical PIS- form.
    static func normalizePrimaryInventorySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIS-") {
            return clean
        }
        return "PIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryInventorySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
