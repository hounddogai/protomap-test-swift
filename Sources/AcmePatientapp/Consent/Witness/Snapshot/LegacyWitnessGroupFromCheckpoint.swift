import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryProxyCheckpointsForGroup(_ items: [PrimaryProxyCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLegacyWitnessGroupsFromCheckpoint(_ items: [PrimaryProxyCheckpoint]) -> [LegacyWitnessGroup] {
        var out: [LegacyWitnessGroup] = []
        for item in items {
            let derived = newLegacyWitnessGroup(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyWitnessGroup(_ item: LegacyWitnessGroup) -> String {
        return classifyLenientProxyReview(item.measuredValue())
    }
}
