import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a rolling care gap review code in its canonical RCGR- form.
    static func normalizeRollingCareGapReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCGR-") {
            return clean
        }
        return "RCGR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingCareGapReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
