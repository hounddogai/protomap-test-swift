import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessTargetsForMapping(_ items: [WitnessTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDisclosureMappingsFromTarget(_ items: [WitnessTarget]) -> [DisclosureMapping] {
        var out: [DisclosureMapping] = []
        for item in items {
            let derived = newDisclosureMapping(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDisclosureMapping(_ item: DisclosureMapping) -> String {
        return classifyRegionalWitnessDraft(item.measuredValue())
    }
}
