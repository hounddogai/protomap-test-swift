import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSummariesForDraft(_ items: [ReferenceRangeSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveReferenceRangeDraftsFromSummary(_ items: [ReferenceRangeSummary]) -> [ReferenceRangeDraft] {
        var out: [ReferenceRangeDraft] = []
        for item in items {
            let derived = newReferenceRangeDraft(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateReferenceRangeDraft(_ item: ReferenceRangeDraft) -> String {
        return referenceRangeSummaryBucket(item.measuredValue())
    }
}
