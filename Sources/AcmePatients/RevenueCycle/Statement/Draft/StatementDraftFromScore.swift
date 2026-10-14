import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyChargeScoresForDraft(_ items: [LegacyChargeScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveStatementDraftsFromScore(_ items: [LegacyChargeScore]) -> [StatementDraft] {
        var out: [StatementDraft] = []
        for item in items {
            let derived = newStatementDraft(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyStatementDraftExtra(_ item: StatementDraft) -> String {
        return classifyRollingChargeSegment(item.adjustedVolume())
    }
}
