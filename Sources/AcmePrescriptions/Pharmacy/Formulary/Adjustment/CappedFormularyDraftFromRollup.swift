import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualFormularyRollupsForDraft(_ items: [ManualFormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveCappedFormularyDraftsFromRollup(_ items: [ManualFormularyRollup]) -> [CappedFormularyDraft] {
        var out: [CappedFormularyDraft] = []
        for item in items {
            let derived = newCappedFormularyDraft(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCappedFormularyDraft(_ item: CappedFormularyDraft) -> String {
        return manualFormularyRollupBucket(item.weightedVolume())
    }
}
