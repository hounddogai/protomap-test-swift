import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictDisclosureSegmentsForRollup(_ items: [StrictDisclosureSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDisclosureRollupsFromSegment(_ items: [StrictDisclosureSegment]) -> [DisclosureRollup] {
        var out: [DisclosureRollup] = []
        for item in items {
            let derived = newDisclosureRollup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeDisclosureRollup(_ item: DisclosureRollup) -> Double {
        return disclosureRequestWeight(6, active: true)
    }
}
