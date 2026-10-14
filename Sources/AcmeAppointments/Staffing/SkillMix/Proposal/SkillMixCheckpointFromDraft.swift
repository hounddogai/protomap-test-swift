import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalShiftDraftsForCheckpoint(_ items: [GlobalShiftDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveSkillMixCheckpointsFromDraft(_ items: [GlobalShiftDraft]) -> [SkillMixCheckpoint] {
        var out: [SkillMixCheckpoint] = []
        for item in items {
            let derived = newSkillMixCheckpoint(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeSkillMixCheckpoint(_ item: SkillMixCheckpoint) -> Double {
        return globalShiftDraftWeight(1, active: true)
    }
}
