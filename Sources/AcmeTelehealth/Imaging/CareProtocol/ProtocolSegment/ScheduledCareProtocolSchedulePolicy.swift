import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a scheduled care protocol schedule code in its canonical SCPS- form.
    static func normalizeScheduledCareProtocolScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPS-") {
            return clean
        }
        return "SCPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledCareProtocolScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
