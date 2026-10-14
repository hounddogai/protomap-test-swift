import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness snapshot code in its canonical WS- form.
    static func normalizeWitnessSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WS-") {
            return clean
        }
        return "WS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func witnessSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
