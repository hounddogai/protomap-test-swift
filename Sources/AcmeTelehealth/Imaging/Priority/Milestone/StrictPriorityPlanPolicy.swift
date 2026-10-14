import AcmePlatform
import Foundation

extension Imaging {
    static func strictPriorityPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a strict priority plan code in its canonical SPP- form.
    static func normalizeStrictPriorityPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPP-") {
            return clean
        }
        return "SPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
