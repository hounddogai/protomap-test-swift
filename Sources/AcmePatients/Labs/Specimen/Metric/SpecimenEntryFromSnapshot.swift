import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSnapshotsForEntry(_ items: [ReferenceRangeSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSpecimenEntriesFromSnapshot(_ items: [ReferenceRangeSnapshot]) -> [SpecimenEntry] {
        var out: [SpecimenEntry] = []
        for item in items {
            let derived = newSpecimenEntry(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileSpecimenEntry(_ item: SpecimenEntry) -> String {
        return classifyReferenceRangeSummary(item.measuredValue())
    }
}
