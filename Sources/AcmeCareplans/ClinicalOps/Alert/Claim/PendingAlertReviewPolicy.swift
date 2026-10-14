import AcmePlatform
import Foundation

extension ClinicalOps {
    static func pendingAlertReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a pending alert review code in its canonical PAR- form.
    static func normalizePendingAlertReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAR-") {
            return clean
        }
        return "PAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
