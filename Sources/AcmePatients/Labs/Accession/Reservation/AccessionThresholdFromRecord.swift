import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeRecordsForThreshold(_ items: [ReferenceRangeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveAccessionThresholdsFromRecord(_ items: [ReferenceRangeRecord]) -> [AccessionThreshold] {
        var out: [AccessionThreshold] = []
        for item in items {
            let derived = newAccessionThreshold(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAccessionThreshold(_ item: AccessionThreshold) -> String {
        return referenceRangeEstimateBucket(item.netTotal())
    }
}
