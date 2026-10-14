import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a handoff milestone code in its canonical HM- form.
    static func normalizeHandoffMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HM-") {
            return clean
        }
        return "HM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func handoffMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func handoffMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
