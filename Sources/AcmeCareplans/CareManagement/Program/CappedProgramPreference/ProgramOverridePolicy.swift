import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a program override score falls in.
    static func classifyProgramOverride(_ score: Double) -> String {
        if score < 9.6 {
            return "medium"
        }
        if score < 50.6 {
            return "ok"
        }
        if score < 65.8 {
            return "high"
        }
        return "elevated"
    }

    static func programOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeProgramOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
