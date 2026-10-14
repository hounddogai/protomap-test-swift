import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyBundlesForBudget(_ items: [StudyBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveModalityBudgetsFromBundle(_ items: [StudyBundle]) -> [ModalityBudget] {
        var out: [ModalityBudget] = []
        for item in items {
            let derived = newModalityBudget(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankModalityBudget(_ item: ModalityBudget) -> String {
        return classifyLegacyStudyEstimate(item.netTotal())
    }

    static func summarizeWorklistBundlesForBudget(_ items: [WorklistBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveModalityBudgetsFromBundleExtra(_ items: [WorklistBundle]) -> [ModalityBudget] {
        var out: [ModalityBudget] = []
        for item in items {
            let derived = newModalityBudget(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankModalityBudgetExtra(_ item: ModalityBudget) -> String {
        return classifyWorklistTemplate(item.netTotal())
    }
}
