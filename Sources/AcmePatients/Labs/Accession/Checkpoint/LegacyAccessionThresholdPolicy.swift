import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy accession threshold code in its canonical LAT- form.
    static func normalizeLegacyAccessionThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAT-") {
            return clean
        }
        return "LAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyAccessionThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
