import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenMetricsForDraft(_ items: [SpecimenMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReferenceRangeDraftsFromMetric(_ items: [SpecimenMetric]) -> [ReferenceRangeDraft] {
        var out: [ReferenceRangeDraft] = []
        for item in items {
            let derived = newReferenceRangeDraft(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitReferenceRangeDraft(_ item: ReferenceRangeDraft) -> String {
        return classifySpecimenTemplate(item.measuredValue())
    }
}
