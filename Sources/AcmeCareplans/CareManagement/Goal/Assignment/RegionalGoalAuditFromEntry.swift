import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultAssessmentEntriesForAudit(_ items: [DefaultAssessmentEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRegionalGoalAuditsFromEntry(_ items: [DefaultAssessmentEntry]) -> [RegionalGoalAudit] {
        var out: [RegionalGoalAudit] = []
        for item in items {
            let derived = newRegionalGoalAudit(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalGoalAudit(_ item: RegionalGoalAudit) -> String {
        return classifyDefaultAssessmentEntry(item.projectedValue())
    }
}
