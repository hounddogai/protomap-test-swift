import AcmePlatform
import Foundation

extension RevenueCycle {
    static func rollingRemittanceAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a rolling remittance assignment code in its canonical RRA- form.
    static func normalizeRollingRemittanceAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRA-") {
            return clean
        }
        return "RRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
