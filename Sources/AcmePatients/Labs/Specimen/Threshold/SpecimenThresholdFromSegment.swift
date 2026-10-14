import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSegmentsForThreshold(_ items: [ReferenceRangeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveSpecimenThresholdsFromSegment(_ items: [ReferenceRangeSegment]) -> [SpecimenThreshold] {
        var out: [SpecimenThreshold] = []
        for item in items {
            let derived = newSpecimenThreshold(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveSpecimenThreshold(_ item: SpecimenThreshold) -> Double {
        return referenceRangeDraftWeight(5, active: true)
    }
}
