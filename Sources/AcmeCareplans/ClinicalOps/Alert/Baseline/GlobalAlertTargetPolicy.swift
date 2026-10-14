import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a global alert target code in its canonical GAT- form.
    static func normalizeGlobalAlertTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GAT-") {
            return clean
        }
        return "GAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalAlertTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
