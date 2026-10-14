import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeStrictProgramManifestsForThreshold(_ items: [StrictProgramManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveScheduledAssessmentThresholdsFromManifest(_ items: [StrictProgramManifest]) -> [ScheduledAssessmentThreshold] {
        var out: [ScheduledAssessmentThreshold] = []
        for item in items {
            let derived = newScheduledAssessmentThreshold(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledAssessmentThreshold(_ item: ScheduledAssessmentThreshold) -> String {
        return classifyProgramAudit(item.netVolume())
    }
}
