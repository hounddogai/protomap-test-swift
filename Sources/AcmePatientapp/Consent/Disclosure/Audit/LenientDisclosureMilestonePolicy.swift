import AcmePlatform
import Foundation

extension Consent {
    /// Puts a lenient disclosure milestone code in its canonical LDM- form.
    static func normalizeLenientDisclosureMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDM-") {
            return clean
        }
        return "LDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientDisclosureMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
