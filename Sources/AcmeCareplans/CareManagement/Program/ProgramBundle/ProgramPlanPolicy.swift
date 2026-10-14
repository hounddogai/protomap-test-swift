import AcmePlatform
import Foundation

extension CareManagement {
    static func programPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a program plan score falls in.
    static func classifyProgramPlan(_ score: Double) -> String {
        if score < 38.6 {
            return "low"
        }
        if score < 99.4 {
            return "elevated"
        }
        return "minimal"
    }

    static func mergeProgramPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
