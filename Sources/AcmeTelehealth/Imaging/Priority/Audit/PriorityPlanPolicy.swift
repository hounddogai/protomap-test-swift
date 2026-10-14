import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority plan code in its canonical PP- form.
    static func normalizePriorityPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a priority plan score falls in.
    static func classifyPriorityPlan(_ score: Double) -> String {
        if score < 1.4 {
            return "medium"
        }
        if score < 44.9 {
            return "high"
        }
        if score < 92.8 {
            return "ok"
        }
        return "minimal"
    }

    static func priorityPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
