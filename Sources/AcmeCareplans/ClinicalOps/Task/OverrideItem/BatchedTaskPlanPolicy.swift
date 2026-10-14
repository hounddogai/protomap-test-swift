import AcmePlatform
import Foundation

extension ClinicalOps {
    static func batchedTaskPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched task plan code in its canonical BTP- form.
    static func normalizeBatchedTaskPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BTP-") {
            return clean
        }
        return "BTP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedTaskPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
