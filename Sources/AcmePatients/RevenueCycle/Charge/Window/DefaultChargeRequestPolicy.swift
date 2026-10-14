import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a default charge request code in its canonical DCR- form.
    static func normalizeDefaultChargeRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCR-") {
            return clean
        }
        return "DCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultChargeRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func defaultChargeRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
