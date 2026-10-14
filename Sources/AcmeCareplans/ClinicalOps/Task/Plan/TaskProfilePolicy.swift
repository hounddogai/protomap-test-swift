import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a task profile code in its canonical TP- form.
    static func normalizeTaskProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TP-") {
            return clean
        }
        return "TP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func taskProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
