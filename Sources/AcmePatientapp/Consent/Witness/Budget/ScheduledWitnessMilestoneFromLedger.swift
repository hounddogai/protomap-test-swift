import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedDisclosureLedgersForMilestone(_ items: [CappedDisclosureLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveScheduledWitnessMilestonesFromLedger(_ items: [CappedDisclosureLedger]) -> [ScheduledWitnessMilestone] {
        var out: [ScheduledWitnessMilestone] = []
        for item in items {
            let derived = newScheduledWitnessMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateScheduledWitnessMilestone(_ item: ScheduledWitnessMilestone) -> String {
        return normalizeDisclosureAssignmentCode(item.code)
    }
}
