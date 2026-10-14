import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledShiftTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a scheduled shift template code in its canonical SST- form.
    static func normalizeScheduledShiftTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SST-") {
            return clean
        }
        return "SST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
