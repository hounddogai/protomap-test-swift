import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionTargetsForTier(_ items: [AccessionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedSpecimenTiersFromTarget(_ items: [AccessionTarget]) -> [CappedSpecimenTier] {
        var out: [CappedSpecimenTier] = []
        for item in items {
            let derived = newCappedSpecimenTier(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCappedSpecimenTier(_ item: CappedSpecimenTier) -> String {
        return normalizeAccessionTargetCode(item.code)
    }
}
