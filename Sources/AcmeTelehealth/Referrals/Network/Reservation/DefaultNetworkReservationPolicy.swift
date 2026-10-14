import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a default network reservation code in its canonical DNR- form.
    static func normalizeDefaultNetworkReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DNR-") {
            return clean
        }
        return "DNR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultNetworkReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
