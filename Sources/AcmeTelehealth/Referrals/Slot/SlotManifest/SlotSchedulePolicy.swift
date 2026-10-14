import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot schedule code in its canonical SS- form.
    static func normalizeSlotScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SS-") {
            return clean
        }
        return "SS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func slotScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
