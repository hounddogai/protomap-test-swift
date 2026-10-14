import AcmePlatform
import Foundation

extension Consent {
    static func manualLanguageSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a manual language snapshot code in its canonical MLS- form.
    static func normalizeManualLanguageSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MLS-") {
            return clean
        }
        return "MLS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
