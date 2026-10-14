import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a manual remittance forecast code in its canonical MRF- form.
    static func normalizeManualRemittanceForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRF-") {
            return clean
        }
        return "MRF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualRemittanceForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
