import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessVariancesForGroup(_ items: [WitnessVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveWitnessGroupsFromVariance(_ items: [WitnessVariance]) -> [WitnessGroup] {
        var out: [WitnessGroup] = []
        for item in items {
            let derived = newWitnessGroup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceWitnessGroup(_ item: WitnessGroup) -> String {
        return witnessVarianceBucket(item.measuredValue())
    }
}
