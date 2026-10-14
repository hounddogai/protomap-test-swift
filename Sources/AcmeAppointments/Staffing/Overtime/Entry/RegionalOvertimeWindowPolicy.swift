import AcmePlatform
import Foundation

extension Staffing {
    static func regionalOvertimeWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a regional overtime window code in its canonical ROW- form.
    static func normalizeRegionalOvertimeWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROW-") {
            return clean
        }
        return "ROW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
