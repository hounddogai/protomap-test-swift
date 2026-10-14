import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal panel policy code in its canonical SPP- form.
    static func normalizeSeasonalPanelPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPP-") {
            return clean
        }
        return "SPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalPanelPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
