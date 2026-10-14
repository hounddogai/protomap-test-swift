import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultAssessmentEntriesForBundle(_ items: [DefaultAssessmentEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveAdaptiveOutreachBundlesFromEntry(_ items: [DefaultAssessmentEntry]) -> [AdaptiveOutreachBundle] {
        var out: [AdaptiveOutreachBundle] = []
        for item in items {
            let derived = newAdaptiveOutreachBundle(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyAdaptiveOutreachBundleExtra(_ item: AdaptiveOutreachBundle) -> String {
        return legacyAssessmentProposalBucket(item.projectedTotal())
    }
}
