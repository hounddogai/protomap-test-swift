import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadBudgetsForVariance(_ items: [ReadBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveStudyVariancesFromBudget(_ items: [ReadBudget]) -> [StudyVariance] {
        var out: [StudyVariance] = []
        for item in items {
            let derived = newStudyVariance(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeStudyVariance(_ item: StudyVariance) -> String {
        return classifyReadBudget(item.effectiveTotal())
    }
}
