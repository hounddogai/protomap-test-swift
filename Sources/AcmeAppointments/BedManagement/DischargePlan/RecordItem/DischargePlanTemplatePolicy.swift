import AcmePlatform
import Foundation

extension BedManagement {
    static func dischargePlanTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a discharge plan template code in its canonical DPT- form.
    static func normalizeDischargePlanTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPT-") {
            return clean
        }
        return "DPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dischargePlanTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
