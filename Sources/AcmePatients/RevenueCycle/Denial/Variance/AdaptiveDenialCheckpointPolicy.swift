import AcmePlatform
import Foundation

extension RevenueCycle {
    static func adaptiveDenialCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveDenialCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a adaptive denial checkpoint code in its canonical ADC- form.
    static func normalizeAdaptiveDenialCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ADC-") {
            return clean
        }
        return "ADC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
