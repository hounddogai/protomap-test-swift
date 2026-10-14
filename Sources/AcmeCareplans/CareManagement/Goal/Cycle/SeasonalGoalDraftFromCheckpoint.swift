import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePrimaryProgramCheckpointsForDraft(_ items: [PrimaryProgramCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSeasonalGoalDraftsFromCheckpoint(_ items: [PrimaryProgramCheckpoint]) -> [SeasonalGoalDraft] {
        var out: [SeasonalGoalDraft] = []
        for item in items {
            let derived = newSeasonalGoalDraft(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifySeasonalGoalDraft(_ item: SeasonalGoalDraft) -> String {
        return normalizeBatchedProgramPlanCode(item.code)
    }
}
