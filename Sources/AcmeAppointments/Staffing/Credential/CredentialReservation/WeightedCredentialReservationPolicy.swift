import AcmePlatform
import Foundation

extension Staffing {
    static func weightedCredentialReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func weightedCredentialReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a weighted credential reservation code in its canonical WCR- form.
    static func normalizeWeightedCredentialReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCR-") {
            return clean
        }
        return "WCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
