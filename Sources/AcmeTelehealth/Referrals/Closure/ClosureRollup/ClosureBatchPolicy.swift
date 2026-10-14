import AcmePlatform
import Foundation

extension Referrals {
    static func closureBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.2
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a closure batch code in its canonical CB- form.
    static func normalizeClosureBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CB-") {
            return clean
        }
        return "CB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
