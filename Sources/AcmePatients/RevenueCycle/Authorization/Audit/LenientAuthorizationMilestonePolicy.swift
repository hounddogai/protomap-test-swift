import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a lenient authorization milestone code in its canonical LAM- form.
    static func normalizeLenientAuthorizationMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAM-") {
            return clean
        }
        return "LAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientAuthorizationMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
