import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a acuity plan assignment score falls in.
    static func classifyAcuityPlanAssignment(_ score: Double) -> String {
        if score < 4.9 {
            return "elevated"
        }
        if score < 20.0 {
            return "critical"
        }
        if score < 71.5 {
            return "medium"
        }
        if score < 89.1 {
            return "watch"
        }
        return "ok"
    }

    static func mergeAcuityPlanAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a acuity plan assignment code in its canonical APA- form.
    static func normalizeAcuityPlanAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APA-") {
            return clean
        }
        return "APA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
