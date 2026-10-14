import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualDenialCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func manualDenialCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a manual denial cycle code in its canonical MDC- form.
    static func normalizeManualDenialCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MDC-") {
            return clean
        }
        return "MDC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
