import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyCensusMilestonesForAssignment(_ items: [LegacyCensusMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePrimaryTransferAssignmentsFromMilestone(_ items: [LegacyCensusMilestone]) -> [PrimaryTransferAssignment] {
        var out: [PrimaryTransferAssignment] = []
        for item in items {
            let derived = newPrimaryTransferAssignment(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planPrimaryTransferAssignment(_ item: PrimaryTransferAssignment) -> String {
        return classifyFallbackCensusMetric(item.effectiveVolume())
    }
}
