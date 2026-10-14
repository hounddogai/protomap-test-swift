import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan schedule score falls in.
    static func classifyAcuityPlanSchedule(_ score: Double) -> String {
        if score < 55.6 {
            return "minimal"
        }
        if score < 95.4 {
            return "watch"
        }
        if score < 96.3 {
            return "high"
        }
        return "medium"
    }

    static func acuityPlanScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a acuity plan schedule code in its canonical APS- form.
    static func normalizeAcuityPlanScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APS-") {
            return clean
        }
        return "APS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
