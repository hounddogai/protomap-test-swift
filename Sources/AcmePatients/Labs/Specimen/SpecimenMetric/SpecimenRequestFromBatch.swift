import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackReferenceRangeBatchesForRequest(_ items: [FallbackReferenceRangeBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenRequestsFromBatch(_ items: [FallbackReferenceRangeBatch]) -> [SpecimenRequest] {
        var out: [SpecimenRequest] = []
        for item in items {
            let derived = newSpecimenRequest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveSpecimenRequest(_ item: SpecimenRequest) -> String {
        return normalizeScheduledReferenceRangeSegmentCode(item.code)
    }
}
