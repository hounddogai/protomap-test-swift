import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotDigestsForMilestone(_ items: [SlotDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveClosureMilestonesFromDigest(_ items: [SlotDigest]) -> [ClosureMilestone] {
        var out: [ClosureMilestone] = []
        for item in items {
            let derived = newClosureMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateClosureMilestone(_ item: ClosureMilestone) -> String {
        return classifySlotManifest(item.measuredValue())
    }
}
