import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a network forecast code in its canonical NF- form.
    static func normalizeNetworkForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NF-") {
            return clean
        }
        return "NF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func networkForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
