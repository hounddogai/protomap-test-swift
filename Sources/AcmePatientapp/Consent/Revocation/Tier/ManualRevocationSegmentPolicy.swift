import AcmePlatform
import Foundation

extension Consent {
    static func mergeManualRevocationSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualRevocationSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a manual revocation segment code in its canonical MRS- form.
    static func normalizeManualRevocationSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRS-") {
            return clean
        }
        return "MRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
