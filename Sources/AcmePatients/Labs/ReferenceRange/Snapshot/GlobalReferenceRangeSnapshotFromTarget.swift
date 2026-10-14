import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionTargetsForSnapshot(_ items: [AccessionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalReferenceRangeSnapshotsFromTarget(_ items: [AccessionTarget]) -> [GlobalReferenceRangeSnapshot] {
        var out: [GlobalReferenceRangeSnapshot] = []
        for item in items {
            let derived = newGlobalReferenceRangeSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalReferenceRangeSnapshot(_ item: GlobalReferenceRangeSnapshot) -> Double {
        return accessionBundleWeight(5, active: true)
    }
}
