import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacyAcuityPlanMappingsForEntry(_ items: [LegacyAcuityPlanMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func derivePendingCredentialEntriesFromMapping(_ items: [LegacyAcuityPlanMapping]) -> [PendingCredentialEntry] {
        var out: [PendingCredentialEntry] = []
        for item in items {
            let derived = newPendingCredentialEntry(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePendingCredentialEntry(_ item: PendingCredentialEntry) -> Double {
        return scheduledAcuityPlanAllocationWeight(2, active: true)
    }
}
