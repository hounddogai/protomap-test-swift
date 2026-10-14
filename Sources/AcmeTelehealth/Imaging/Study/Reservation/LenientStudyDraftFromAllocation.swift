import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistAllocationsForDraft(_ items: [WorklistAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientStudyDraftsFromAllocation(_ items: [WorklistAllocation]) -> [LenientStudyDraft] {
        var out: [LenientStudyDraft] = []
        for item in items {
            let derived = newLenientStudyDraft(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLenientStudyDraftExtra(_ item: LenientStudyDraft) -> String {
        return classifyWorklistRecord(item.weightedVolume())
    }
}
