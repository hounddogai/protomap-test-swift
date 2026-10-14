import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan draft code in its canonical APD- form.
    static func normalizeAcuityPlanDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APD-") {
            return clean
        }
        return "APD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAcuityPlanDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func acuityPlanDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
