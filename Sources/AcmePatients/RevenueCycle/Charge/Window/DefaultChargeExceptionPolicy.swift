import AcmePlatform
import Foundation

extension RevenueCycle {
    static func defaultChargeExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func defaultChargeExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a default charge exception code in its canonical DCE- form.
    static func normalizeDefaultChargeExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCE-") {
            return clean
        }
        return "DCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
